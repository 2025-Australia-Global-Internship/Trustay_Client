package com.maritel.trustay.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.ColumnDefault;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@EntityListeners(value = {AuditingEntityListener.class})
@MappedSuperclass
@Getter
@Setter
public class BaseEntity {

    @CreatedDate
    @Column(name = "regTime", nullable = false, updatable = false)
    private LocalDateTime regTime;

    @LastModifiedDate
    @Column(name = "modTime")
    private LocalDateTime modTime;

    @PrePersist
    public void prePersist() {
        this.regTime = LocalDateTime.now();
        this.modTime = LocalDateTime.now(); // 생성 시점에도 값 넣어줌
    }

    @PreUpdate
    public void preUpdate() {
        this.modTime = LocalDateTime.now();
    }
}
