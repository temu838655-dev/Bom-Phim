# Bom Phim

Ứng dụng xem phim iOS viết bằng SwiftUI, sử dụng PhimAPI để tải dữ liệu phim.

## Tình trạng
- [x] Khung ứng dụng SwiftUI
- [x] Trang chủ phim mới cập nhật
- [x] Tìm kiếm phim
- [x] Chi tiết phim và danh sách tập
- [x] Phát video bằng AVPlayer
- [x] Lưu yêu thích và lịch sử xem trên thiết bị
- [x] GitHub Actions build kiểm tra iOS Simulator
- [ ] Ký ứng dụng và xuất IPA cài lên iPhone
- [ ] Tùy chỉnh phụ đề (cỡ chữ, màu sắc)
- [ ] Hồ sơ người dùng và mã PIN

## Build
Dự án dùng XcodeGen. Cài XcodeGen, sau đó chạy:

```sh
xcodegen generate
xcodebuild -project BomPhim.xcodeproj -scheme BomPhim -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

## Lưu ý
Workflow hiện tạo bản build cho iOS Simulator để kiểm tra biên dịch. Đây chưa phải IPA cài trực tiếp lên iPhone. Muốn cài lên iPhone cần ký ứng dụng bằng chứng chỉ/provisioning hợp lệ hoặc dùng quy trình sideload phù hợp.

API: https://phimapi.com/
