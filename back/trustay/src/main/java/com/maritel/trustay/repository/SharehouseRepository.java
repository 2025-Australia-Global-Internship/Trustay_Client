package com.maritel.trustay.repository;

import com.maritel.trustay.entity.Sharehouse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

@Repository
public interface SharehouseRepository extends JpaRepository<Sharehouse, Long>, SharehouseRepositoryCustom {
    // 기존 JpaSpecificationExecutor<Sharehouse>는 제거해도 됨 (이제 안 쓰니까)
    Page<Sharehouse> findByHostEmail(String email, Pageable pageable);

    @Modifying(clearAutomatically = true)
    @Query("UPDATE Sharehouse s SET s.viewCount = s.viewCount + 1 WHERE s.id = :id")
    void updateViewCount(Long id);
}