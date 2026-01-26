package com.maritel.trustay.service;

import com.maritel.trustay.util.FileUtils;
import jakarta.transaction.Transactional;
import lombok.extern.slf4j.Slf4j;
import org.apache.coyote.BadRequestException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.net.MalformedURLException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
@Transactional
@Slf4j
public class FileService {

    @Value("${pkg.imgLocation}")
    private String imageStoragePath;

    @Value("${pkg.server.domain}")
    private String serverDomain;

    @Value("${pkg.file.prefix}")
    private String filePrefix;

    public String uploadFile(MultipartFile file) throws MalformedURLException, BadRequestException {
        if (file == null) {
            throw new BadRequestException("파일이 제공되지 않았습니다.");
        }

        String fileExt = FileUtils.extension(file.getContentType());

        log.debug("** fileUpload originalFileName = {} **", file.getOriginalFilename());

        if (fileExt.equals(".jpg") || fileExt.equals(".jpeg") || fileExt.equals(".png") || fileExt.equals(".heic") || fileExt.equals(".heif")) {
            String fileName = this.getNewFileName(fileExt);
            String url = this.uploadLocal(fileName, file);
            log.info(">>>>  fileUpload fileurl {}**", url);
            return url;
        } else {
            log.warn("지원하지 않는 파일 형식: {}", fileExt);
            return null;
        }
    }

    public List<String> uploadFiles(List<MultipartFile> files) throws MalformedURLException, BadRequestException {
        if (files == null || files.isEmpty()) {
            return List.of();
        }

        List<String> urls = new ArrayList<>();
        for (MultipartFile file : files) {
            if (file == null || file.isEmpty()) continue;
            String url = uploadFile(file);
            if (url != null && !url.isBlank()) {
                urls.add(url);
            }
        }
        return urls;
    }

    private String uploadLocal(String filename, MultipartFile file) throws MalformedURLException {
        LocalDate nowDate = LocalDate.now();
        String datePath = String.format("%04d/%02d/%02d",
                nowDate.getYear(),
                nowDate.getMonth().getValue(),
                nowDate.getDayOfMonth());

        String fullPath = imageStoragePath + "/" + datePath;
        FileUtils.hasDirectoryAndMkDir(fullPath);

        try {
            File dir = new File(fullPath);
            if (!dir.exists()) {
                boolean mkdir = dir.mkdirs();
                log.debug("디렉토리 생성 성공: {}", mkdir);
            }

            FileOutputStream fileOutputStream = new FileOutputStream(new File(dir, filename));
            BufferedOutputStream stream = new BufferedOutputStream(fileOutputStream);
            stream.write(file.getBytes());
            stream.close();

        } catch (IOException e) {
            log.error("파일 업로드 중 오류 발생", e);
            throw new RuntimeException("파일 업로드 실패: " + e.getLocalizedMessage());
        }

        // URL 생성 (File.separator 대신 "/" 사용)
        String uploadedURLPath = String.format("https://%s/images/%s/%s",
                serverDomain, datePath, filename);
        return uploadedURLPath;
    }

    /* 새 파일명 규칙 적용 */
    public String getNewFileName(String fileExt) {
        String randomStr = UUID.randomUUID().toString().replace("-", "");
        DateTimeFormatter dateTimeFormatter = DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss");
        String formatTime = LocalDateTime.now().format(dateTimeFormatter);

        String newFileName = String.format("%s_%s_%s%s",
                filePrefix, randomStr, formatTime, fileExt);

        log.debug("생성된 파일명: {}", newFileName);
        return newFileName;
    }
}