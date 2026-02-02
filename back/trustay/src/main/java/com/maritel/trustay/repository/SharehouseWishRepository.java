package com.maritel.trustay.repository;

import com.maritel.trustay.entity.SharehouseWish;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface SharehouseWishRepository extends JpaRepository<SharehouseWish, Long> {

    Optional<SharehouseWish> findByMember_IdAndSharehouse_Id(Long memberId, Long sharehouseId);

    boolean existsByMember_IdAndSharehouse_Id(Long memberId, Long sharehouseId);

    Page<SharehouseWish> findByMember_IdOrderByRegTimeDesc(Long memberId, Pageable pageable);
}
