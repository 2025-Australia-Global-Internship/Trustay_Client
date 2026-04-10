package com.maritel.trustay.repository;

import com.maritel.trustay.entity.Member;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface MemberRepository extends JpaRepository<Member, Long> {

    Optional<Member> findByName(String name);

    Optional<Member> findByEmail(String email);

    @EntityGraph(attributePaths = "profile")
    @Query("SELECT m FROM Member m WHERE m.id = :id")
    Optional<Member> findWithProfileById(@Param("id") Long id);
}
