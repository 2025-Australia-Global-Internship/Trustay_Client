package com.maritel.trustay.repository;

import com.maritel.trustay.constant.PaymentStatus;
import com.maritel.trustay.entity.Payment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PaymentRepository extends JpaRepository<Payment, Long> {

    Optional<Payment> findByOrderId(String orderId);

    List<Payment> findByMember_IdAndStatusOrderByRegTimeDesc(Long memberId, PaymentStatus status);
}
