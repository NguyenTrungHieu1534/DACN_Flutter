## ✅ To-Do List

### 🎨 Giao diện
- [ ] Thiết kế **Profile**, **Favorite**, **Album**
- [ ] Thiết kế lại **Search Page**
- [ ] Thêm phần **Settings** trong Profile

### 🎵 Chức năng phát nhạc
- [ ] Thêm **Animation cho Player**:
  - Thanh trượt (slide)
  - Repeat
  - Chuyển hướng đến bài khác
  - Shuffle play (phát ngẫu nhiên)
- [ ] Hiển thị **Lyrics (Lời bài hát)**

### 📂 Playlist
- [+] Thêm Playlist  
- [+] Xóa Playlist  
- [+] Sửa Playlist  

### 🔔 Thông báo & Kết nối
- [+] Hiển thị **trạng thái kết nối**
- [ ] Thêm **thông báo đẩy (push notification)** khi thay đổi trạng thái nhạc

### 🌐 Cộng đồng & Chia sẻ
- [ ] Tạo **report nhạc**, **community**
- [ ] Thêm **chức năng chia sẻ** và **tạo link bài hát**
### CẦN THIẾT KẾ LẠI UI CHO TOÀN BỘ

###### Cần làm bộ điều khiện player, chuyển bài , phát ngẫu nhiên và lặp lại bài hát.
###### LƯU Ý
<h1 style="color:red; font-size:28px; font-weight:bold;"> ⚠️ LƯU Ý QUAN TRỌNG KHI VIẾT CODE FLUTTER ⚠️ </h1> <p style="color:red; font-size:20px; font-weight:bold;"> Mỗi khi tạo một widget hiển thị gì đó lên màn hình, hãy tách nó ra thành một file riêng trong thư mục <code>widgets/</code> rồi import vào màn hình chính. </p> <p style="color:red; font-size:20px; font-weight:bold;"> Điều này giúp dễ quản lý, dễ xử lý code, và dễ tìm widget khi cần sửa chữa hoặc tái sử dụng. </p> <p style="color:red; font-size:20px; font-weight:bold;"> Tránh nhồi tất cả widget vào một file trong <code>screens/</code> — ví dụ như <code>library_screen.dart</code> đang quá dài, khó đọc, khó biết đoạn nào xử lý phần nào. ĐỪNG ĐỂ FILE DÀI 500+ DÒNG CHỈ VÌ LƯỜI TÁCH WIDGET! 😤 </p>