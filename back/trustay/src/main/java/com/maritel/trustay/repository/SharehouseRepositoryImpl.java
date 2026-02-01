package com.maritel.trustay.repository;

import com.maritel.trustay.constant.ApprovalStatus;
import com.maritel.trustay.constant.HouseType;
import com.maritel.trustay.dto.req.SharehouseSearchReq;
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

    @Override
    public Page<Sharehouse> search(SharehouseSearchReq req, Pageable pageable) {

        // 1. 컨텐츠 조회
        List<Sharehouse> content = queryFactory
                .selectFrom(sharehouse)
                .where(
                        isApproved(), // 기본 조건: 승인된 매물만
                        containsKeyword(req.getKeyword()),
                        eqHouseType(req.getHouseType()),
                        goeMinPrice(req.getMinPrice()),
                        loeMaxPrice(req.getMaxPrice()),
                        // 상세 조건
                        goeRoomCount(req.getMinRoomCount()),
                        goeBathroomCount(req.getMinBathroomCount()),
                        eqCurrentResidents(req.getCurrentResidents()),
                        containsAllOptions(req.getOptions()) // 옵션 필터
                )
                .orderBy(getOrderSpecifier(pageable)) // 동적 정렬 적용
                .offset(pageable.getOffset())
                .limit(pageable.getPageSize())
                .fetch();

        // 2. 카운트 쿼리 (페이징 필수)
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

    // --- [BooleanExpression: 검색 조건들] ---

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

    // [옵션 검색] 사용자가 선택한 옵션들을 "모두" 가지고 있는지 확인 (AND 조건)
    private BooleanExpression containsAllOptions(List<String> options) {
        if (options == null || options.isEmpty()) return null;

        // DB에 "WIFI,PARKING" 처럼 저장되어 있다고 가정
        BooleanExpression result = null;
        for (String option : options) {
            if (result == null) {
                result = sharehouse.options.contains(option);
            } else {
                result = result.and(sharehouse.options.contains(option)); // AND로 연결
            }
        }
        return result;
    }

    // --- [동적 정렬 처리 메서드] ---
    private OrderSpecifier<?>[] getOrderSpecifier(Pageable pageable) {
        if (pageable.getSort().isEmpty()) {
            return new OrderSpecifier[]{sharehouse.viewCount.desc()}; // 기본값: 조회수 내림차순
        }

        List<OrderSpecifier<?>> orders = new ArrayList<>();
        for (Sort.Order order : pageable.getSort()) {
            Order direction = order.isAscending() ? Order.ASC : Order.DESC;
            // 동적으로 컬럼명을 매칭시킴
            PathBuilder<Sharehouse> pathBuilder = new PathBuilder<>(sharehouse.getType(), sharehouse.getMetadata());
            orders.add(new OrderSpecifier(direction, pathBuilder.get(order.getProperty())));
        }
        return orders.toArray(new OrderSpecifier[0]);
    }
}