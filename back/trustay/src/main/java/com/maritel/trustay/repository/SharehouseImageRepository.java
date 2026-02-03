package com.maritel.trustay.repository;

import com.maritel.trustay.entity.SharehouseImage;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface SharehouseImageRepository extends JpaRepository<SharehouseImage, Long> {
    // 특정 쉐어하우스에 연결된 이미지들 찾기
    List<SharehouseImage> findBySharehouseId(Long houseId);

    // 수정 시 기존 이미지 관계 삭제용
    void deleteBySharehouseId(Long houseId);
}