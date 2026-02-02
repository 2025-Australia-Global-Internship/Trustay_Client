package com.maritel.trustay.repository;

import com.maritel.trustay.constant.ApprovalStatus;
import com.maritel.trustay.constant.HouseType;
import com.maritel.trustay.dto.req.SharehouseSearchReq;
import com.maritel.trustay.entity.QSharehouse; // 명시적 임포트 확인
import com.maritel.trustay.entity.Sharehouse;
import com.querydsl.core.types.Order;
import com.querydsl.core.types.OrderSpecifier;
import com.querydsl.core.types.dsl.BooleanExpression;
import com.querydsl.core.types.dsl.PathBuilder;
import com.querydsl.jpa.impl.JPAQueryFactory;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.util.StringUtils;

import java.util.ArrayList;
import java.util.List;

import static com.maritel.trustay.entity.QSharehouse.sharehouse;

@RequiredArgsConstructor
public class SharehouseRepositoryImpl implements SharehouseRepositoryCustom {

    private final JPAQueryFactory queryFactory;

    // [수정] 서비스에서 호출하는 이름인 searchSharehouses로 변경
    @Override
    public Page<Sharehouse> searchSharehouses(SharehouseSearchReq req, Pageable pageable) {

        List<Sharehouse> content = queryFactory
                .selectFrom(sharehouse)
                .where(
                        isApproved(),
                        containsKeyword(req.getKeyword()),
                        eqHouseType(req.getHouseType()),
                        goeMinPrice(req.getMinPrice()),
                        loeMaxPrice(req.getMaxPrice()),
                        goeRoomCount(req.getMinRoomCount()),
                        goeBathroomCount(req.getMinBathroomCount()),
                        eqCurrentResidents(req.getCurrentResidents()),
                        containsAllOptions(req.getOptions())
                )
                .orderBy(getOrderSpecifier(pageable))
                .offset(pageable.getOffset())
                .limit(pageable.getPageSize())
                .fetch();

        // [수정] fetchCount()는 deprecated 되었으므로 select(sharehouse.count()) 방식 사용 (이미 잘 작성됨)
        Long total = queryFactory
                .select(sharehouse.count())
                .from(sharehouse)
                .where(
                        isApproved(),
                        containsKeyword(req.getKeyword()),
                        eqHouseType(req.getHouseType()),
                        goeMinPrice(req.getMinPrice()),
                        loeMaxPrice(req.getMaxPrice()),
                        goeRoomCount(req.getMinRoomCount()),
                        goeBathroomCount(req.getMinBathroomCount()),
                        eqCurrentResidents(req.getCurrentResidents()),
                        containsAllOptions(req.getOptions())
                )
                .fetchOne();

        return new PageImpl<>(content, pageable, total != null ? total : 0L);
    }

    private BooleanExpression isApproved() {
        return sharehouse.approvalStatus.eq(ApprovalStatus.ACTIVE);
    }

    private BooleanExpression containsKeyword(String keyword) {
        if (!StringUtils.hasText(keyword)) return null;
        return sharehouse.title.contains(keyword).or(sharehouse.address.contains(keyword));
    }

    private BooleanExpression eqHouseType(HouseType houseType) {
        return houseType != null ? sharehouse.houseType.eq(houseType) : null;
    }

    private BooleanExpression goeMinPrice(Integer minPrice) {
        return minPrice != null ? sharehouse.rentPrice.goe(minPrice) : null;
    }

    private BooleanExpression loeMaxPrice(Integer maxPrice) {
        return maxPrice != null ? sharehouse.rentPrice.loe(maxPrice) : null;
    }

    private BooleanExpression goeRoomCount(Integer count) {
        return count != null ? sharehouse.roomCount.goe(count) : null;
    }

    private BooleanExpression goeBathroomCount(Integer count) {
        return count != null ? sharehouse.bathroomCount.goe(count) : null;
    }

    private BooleanExpression eqCurrentResidents(Integer count) {
        return count != null ? sharehouse.currentResidents.eq(count) : null;
    }

    private BooleanExpression containsAllOptions(List<String> options) {
        if (options == null || options.isEmpty()) return null;

        BooleanExpression result = null;
        for (String option : options) {
            if (result == null) {
                result = sharehouse.options.contains(option);
            } else {
                result = result.and(sharehouse.options.contains(option));
            }
        }
        return result;
    }

    // [수정] 제네릭 타입 명시 및 형변환 에러 해결
    private OrderSpecifier<?>[] getOrderSpecifier(Pageable pageable) {
        if (pageable.getSort().isEmpty()) {
            return new OrderSpecifier[]{new OrderSpecifier<>(Order.DESC, sharehouse.viewCount)};
        }

        List<OrderSpecifier<?>> orders = new ArrayList<>();
        for (Sort.Order order : pageable.getSort()) {
            Order direction = order.isAscending() ? Order.ASC : Order.DESC;
            PathBuilder<Sharehouse> pathBuilder = new PathBuilder<>(sharehouse.getType(), sharehouse.getMetadata());
            // [수정] OrderSpecifier 생성 시 제네릭과 타입을 명확히 함
            orders.add(new OrderSpecifier(direction, pathBuilder.get(order.getProperty())));
        }
        return orders.toArray(new OrderSpecifier[0]);
    }
}