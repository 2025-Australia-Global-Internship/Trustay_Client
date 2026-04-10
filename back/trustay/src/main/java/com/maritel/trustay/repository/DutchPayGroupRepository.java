package com.maritel.trustay.repository;

import com.maritel.trustay.entity.DutchPayGroup;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DutchPayGroupRepository extends JpaRepository<DutchPayGroup, Long> {
}
