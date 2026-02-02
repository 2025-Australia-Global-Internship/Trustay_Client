package com.maritel.trustay.repository;

import com.maritel.trustay.dto.req.SharehouseSearchReq;
import com.maritel.trustay.entity.Sharehouse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface SharehouseRepositoryCustom {
    Page<Sharehouse> searchSharehouses(SharehouseSearchReq req, Pageable pageable);
}