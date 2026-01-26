package com.maritel.trustay.repository;

import com.maritel.trustay.entity.SharehouseCommunity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface SharehouseCommunityRepository extends JpaRepository<SharehouseCommunity, Long> {

    Optional<SharehouseCommunity> findBySharehouseId(Long sharehouseId);
}
