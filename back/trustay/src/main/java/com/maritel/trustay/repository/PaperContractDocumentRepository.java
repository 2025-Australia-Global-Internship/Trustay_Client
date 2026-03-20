package com.maritel.trustay.repository;

import com.maritel.trustay.entity.PaperContractDocument;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PaperContractDocumentRepository extends JpaRepository<PaperContractDocument, Long> {

    List<PaperContractDocument> findByChatRoom_IdOrderByRegTimeDesc(Long roomId);
}
