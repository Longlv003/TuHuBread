# Kịch bản demo bảo vệ tốt nghiệp — TuhuBread

Hệ thống gồm 3 thành phần: **App khách hàng (Flutter)** · **Shop Portal (web)** · **Admin Portal (web)** — dùng chung một backend Node/Express + MongoDB, realtime bằng Socket.IO, thông báo đẩy Firebase Cloud Messaging, thanh toán VNPay Sandbox.

> **Dữ liệu demo đã được nạp vào database và kiểm chứng xong.** Bạn không cần chạy lại gì cả, trừ khi muốn làm mới.

---

## 1. Trạng thái hiện tại

### 1.1. Dữ liệu đã có trong DB

| Chỉ số | Giá trị |
|---|---|
| Tổng đơn hàng | **1.526** (trước đó chỉ có 54, và đều đã cũ hơn 1 tháng) |
| Lịch sử | trải đều **60 ngày gần nhất**, cuối tuần đông hơn ngày thường |
| Doanh thu 30 ngày của shop demo | **26.627.000đ / 222 đơn** |
| Doanh thu 30 ngày toàn sàn | **69.525.450đ / 634 đơn** |
| Đơn hôm nay của shop demo | **16** — 3 chờ xác nhận · 2 đã xác nhận · 2 đang chuẩn bị · 1 đang giao · 7 hoàn thành · 1 đã huỷ |
| Đánh giá | **602** đánh giá mới → điểm shop demo **4.3★ (217 đánh giá)** |
| Sản phẩm shop demo | 13 (đã bổ sung 6 món có ảnh + topping) |
| Voucher | 11 mã dùng được, đã gia hạn tới **19/10/2026** |

Đã kiểm chứng bằng cách gọi thẳng các service mà giao diện dùng: Dashboard shop, Báo cáo 7/30/90 ngày, Dashboard admin, danh sách đơn, chi tiết đơn, `/api/shops`, `/api/products`, `/api/categories` — tất cả trả về đúng số liệu.

### 1.2. Nếu cần nạp lại hoặc gỡ bỏ

```bash
cd be && npm run seed:demo
```

```bash
cd be && npm run seed:demo:undo
```

Script chỉ đụng dữ liệu do chính nó tạo (đánh dấu bằng trường `_seed`), và có sao lưu hạn voucher + điểm đánh giá gốc để hoàn tác chính xác. **Không đụng tới Firebase — mọi mật khẩu giữ nguyên như bạn đang dùng.**

### 1.3. Checklist bắt buộc kiểm tra tối nay

| # | Việc | Cách kiểm tra |
|---|------|----------------|
| 1 | **MongoDB nằm ở máy khác qua ZeroTier** (`10.144.195.81:27018`) | Sáng mai máy đó **phải bật và cùng mạng ZeroTier**, nếu không backend chết ngay khi khởi động. Đây là rủi ro số một → xem mục 6.1. |
| 2 | **IP backend trong app Flutter** | `tuhubread/env` đang là `DEV_URL=http://192.168.1.50:3000`, máy bạn hiện có IP LAN `192.168.1.12`. **Phải sửa đúng IP máy chạy backend** rồi build lại app. |
| 3 | Điện thoại cùng Wi-Fi với máy chạy backend | Mở trình duyệt trên điện thoại vào `http://<IP-máy>:3000/api/banners` — phải ra JSON. |
| 4 | **VNPay return URL** | `.env` đang là `http://10.0.2.2:3000/...` — chỉ đúng với Android Emulator. Demo trên máy thật phải đổi thành `http://<IP-LAN>:3000/api/payment/vnpay-return`. |
| 5 | Firewall Windows mở port 3000 | Nếu máy tính gọi được API mà điện thoại thì không → mở inbound rule cho port 3000. |
| 6 | **Chạy thử trọn vẹn kịch bản tối nay** | Đừng để lần chạy đầu tiên là lúc đứng trước hội đồng. |

### 1.4. Mở sẵn trước khi trình bày

- Terminal đã chạy `cd be && npm start` — giữ nguyên cửa sổ để hội đồng thấy log realtime.
- Tab 1: `http://localhost:3000/admin/login`
- Tab 2: `http://localhost:3000/shop/login` — dùng **cửa sổ ẩn danh** để hai phiên đăng nhập không đá nhau.
- Điện thoại đã cài app, **đã đăng xuất** để demo màn hình đăng nhập.
- Chia đôi màn chiếu: trái Shop Portal, phải màn hình điện thoại (scrcpy hoặc quay màn hình).

---

## 2. Tài khoản dùng khi demo

Đều là **tài khoản sẵn có của bạn — mật khẩu giữ nguyên**, script không đổi gì.

| Vai trò | Email | Ghi chú |
|---|---|---|
| Admin Portal | `admin@gmail.com` | Admin TuHu |
| Shop Portal | `luna148202aacc@gmail.com` | Chủ **Tuhubread - Demo** — đây là shop demo chính |
| App khách hàng | `abcd@gmail.com` | Khách "Luan" — **7 địa chỉ Hà Nội**, 400 đơn, 246 đánh giá, 18 thông báo. Dùng tài khoản này. |
| App (dự phòng) | `long13112k3@gmail.com` | Khách "Văn Long" — 2 địa chỉ Hà Nội, 150 đơn |

> ⚠️ Shop Portal chỉ quản lý **một cửa hàng cho mỗi chủ tài khoản** (`findByOwnerId` trả về một shop). Đăng nhập `luna148202aacc@gmail.com` sẽ vào đúng **Tuhubread - Demo**.

---

## 3. Bản đồ dữ liệu — đọc kỹ chỗ này

Ba cửa hàng `Cơ sở Lê Duẩn / Nguyễn Văn Linh / Điện Biên Phủ` nằm ở **Đà Nẵng**, còn `Tuhubread - Demo` và `BanhMi - Van Long` ở **Hà Nội**. Khách demo (`abcd@gmail.com`) có địa chỉ Hà Nội, nên:

| Cửa hàng | Vị trí | Khoảng cách tới khách demo | Vai trò trong buổi demo |
|---|---|---|---|
| **Tuhubread - Demo** | Hà Nội | 3.4 km | **Shop chính** — đặt hàng, xử lý đơn, báo cáo |
| **BanhMi - Van Long** | Hà Nội | 7.6 km | Shop thứ hai — để demo "đổi cửa hàng phải xoá giỏ" |
| 3 × Cơ sở … | Đà Nẵng | ~610 km | **Không hiện trên app** (ngoài bán kính 10km) — chỉ đóng góp số liệu cho Dashboard Admin toàn sàn |

Điều này **có lợi**: nó chứng minh bộ lọc theo khoảng cách đang chạy thật. Nếu hội đồng hỏi "sao chỉ thấy 2 quán", trả lời: *"App chỉ hiện cửa hàng trong bán kính 10km quanh địa chỉ đang chọn; ba cơ sở còn lại ở Đà Nẵng nên bị lọc ra — có thể kiểm chứng bằng cách đổi sang một địa chỉ ở Đà Nẵng."*

### Menu shop demo (13 món, giá đã tính khuyến mãi)

| Món | Biến thể | Topping |
|---|---|---|
| **Bánh mì pate đặc biệt** | Size thường 25.000đ · Size lớn ~~32.000~~ **29.000đ** | 3 |
| **Trà sữa Thái xanh** | Size M 25.000đ · Size L ~~30.000~~ **27.000đ** | 4 |
| **Combo TuHu tiết kiệm** | 1 người ~~45.000~~ **39.000đ** · 2 người ~~85.000~~ **75.000đ** | 1 |
| Bánh mì xá xíu | Size thường 27.000đ · Size lớn 34.000đ | 2 |
| Bánh mì gà xé phô mai | Size thường 26.000đ | 2 |
| Cà phê sữa đá | Size M 18.000đ · Size L 22.000đ | — |
| Nước ép cam tươi | Chai 350ml 30.000đ | 2 |
| *(và 6 món cũ của bạn)* | | |

> **Ba biến thể cố tình để tồn kho thấp** (cho khối cảnh báo ở Dashboard): `Bánh mì thịt nướng / Size thường = 4`, `/ Size lớn = 3`, `Bánh mì chay / Size thường = 2`. **Đừng đặt ba món này khi demo** — các món in đậm ở trên đã được đảm bảo còn nhiều hàng.

### Voucher dùng được (đã gia hạn tới 19/10/2026)

| Mã | Loại | Ưu đãi | Đơn tối thiểu |
|---|---|---|---|
| `TUHU10` | shop | giảm 10% | 30.000đ |
| `TUHUFREESHIP` | shop | miễn phí ship | 50.000đ |
| `TUHUGIAM20K` | shop | giảm 20.000đ | 100.000đ |
| `WELCOME10` | sàn | giảm 10% (tối đa 20.000đ) | không |
| `FREESHIP` | sàn | miễn phí ship | 50.000đ |
| `GIAM20K` | sàn | giảm 20.000đ | 100.000đ |

---

## 4. Kịch bản chạy — 13 phút

> Nguyên tắc: **mỗi màn hình chỉ nói một câu giá trị**. Đừng đọc lại thứ đang hiện trên màn hình — hội đồng nhìn được rồi.

---

### Màn 1 — Admin Portal: quản trị toàn sàn *(2 phút)*

Đăng nhập `admin@gmail.com` → `/admin/dashboard`

1. **Dashboard**: 4 thẻ KPI (doanh thu ~69,5 triệu, 634 đơn trong kỳ, 5 cửa hàng, 10 khách hàng) và biểu đồ doanh thu 30 ngày.
   > *Câu nói:* "Toàn bộ số liệu này được tổng hợp bằng aggregation pipeline của MongoDB ngay lúc mở trang, không lưu bảng thống kê riêng — nên không bao giờ lệch với dữ liệu gốc."
2. Đổi bộ lọc **7 ngày → 30 ngày** để biểu đồ vẽ lại. Chi tiết nhỏ này dễ ăn điểm.
3. Vào **Quản lý chi nhánh** → 5 cửa hàng kèm chủ sở hữu và điểm đánh giá. Bấm **Sửa** một chi nhánh để cho thấy admin cập nhật được thông tin và ghim lại toạ độ trên bản đồ.
   > ⚠️ **Không hứa "duyệt shop" ở màn này** — chưa có nút đổi trạng thái `pending → active`. Nếu bị hỏi, trả lời theo mục 5.
4. Vào **Danh mục** → 8 danh mục dùng chung toàn sàn.
   > *Câu nói:* "Danh mục do admin quản lý tập trung, shop chỉ được gán sản phẩm vào danh mục có sẵn — nhờ vậy việc lọc và tìm kiếm ở app luôn nhất quán giữa các cửa hàng."
5. Vào **Người dùng** → chỉ vào nút khoá tài khoản.
   > *Câu nói:* "Khi admin khoá, phiên đăng nhập Firebase vẫn còn hiệu lực, nên em kiểm tra lại trạng thái tài khoản trong DB ở mọi cửa vào của portal chứ không tin mỗi token."

---

### Màn 2 — Shop Portal: nghiệp vụ cửa hàng *(2 phút)*

Cửa sổ ẩn danh → `luna148202aacc@gmail.com` → vào **Tuhubread - Demo**

1. **Dashboard**: doanh thu hôm nay ~856.000đ, 16 đơn hôm nay, hàng đợi chờ xác nhận, bảng đơn mới nhất, top món bán chạy hôm nay, và **khối cảnh báo: 3 biến thể sắp hết hàng + đơn chưa thanh toán**.
   > *Câu nói:* "Doanh thu tính trong ngày, nhưng hàng đợi 'chờ xác nhận' đếm toàn bộ — đơn từ hôm qua chưa xử lý thì hôm nay vẫn phải làm, ẩn đi là bỏ sót việc."
2. Vào **Sản phẩm** → mở **Trà sữa Thái xanh** → cho xem **2 biến thể (Size M/L) và 4 topping**.
   > *Câu nói:* "Một sản phẩm tách thành biến thể — quyết định giá và tồn kho — và tuỳ chọn cộng thêm tiền. Nhờ vậy một món ra được hàng chục cấu hình mà không phải tạo hàng chục sản phẩm."
3. **Thêm một biến thể mới** ngay tại chỗ (ví dụ "Size XL — 35.000đ — tồn 20") để chứng minh CRUD chạy thật.
4. Vào **Voucher** → tạo voucher shop mới `DEMO10K`, giảm 10.000đ cho đơn từ 50.000đ. **Giữ mã này để dùng ở Màn 3.**

*(Giữ nguyên tab này, lát nữa quay lại.)*

---

### Màn 3 — App khách hàng: đặt hàng *(4 phút — phần quan trọng nhất)*

Đăng nhập `abcd@gmail.com`

1. **Trang chủ**: banner, danh mục, và **2 cửa hàng gần bạn** kèm khoảng cách 3.4km / 7.6km.
   > *Câu nói:* "App gửi kèm toạ độ của khách; server tính khoảng cách Haversine tới từng cửa hàng, lọc trong bán kính 10km rồi xếp gần nhất lên đầu. Cửa hàng chỉ hiện khi đang hoạt động, còn ít nhất một sản phẩm bán được và chủ shop không bị khoá."
2. Bấm chuông **Thông báo** — có sẵn thông báo hệ thống, voucher và đơn hàng.
3. Vào **Tuhubread - Demo** → mở **Bánh mì pate đặc biệt**:
   - chọn **Size lớn** — đang giảm còn **29.000đ**, chỉ vào giá gạch ngang
   - tick **Thêm trứng ốp la (+7.000đ)** và **Thêm pate (+5.000đ)** → **giá cộng lên realtime**
   - ghi chú "Ít rau giúp em" → **Thêm vào giỏ**
4. Thêm **Cà phê sữa đá — Size L** để giỏ có 2 dòng.
5. *(Điểm cộng)* Quay ra, thử thêm một món của **BanhMi - Van Long** → app hỏi **"Giỏ hàng chỉ chứa món của một cửa hàng, bạn có muốn xoá giỏ cũ?"**
   > *Câu nói:* "Ràng buộc một đơn thuộc một cửa hàng, vì phí ship và thời gian chuẩn bị tính theo từng cửa hàng. Các sàn giao đồ ăn thực tế cũng làm vậy."
6. Vào **Giỏ hàng** → **Thanh toán**.
7. Ở màn Thanh toán, **làm chậm lại ba thao tác này** — đây là chỗ ghi điểm:
   - **Đổi địa chỉ** giữa hai địa chỉ Hà Nội gần/xa → **phí ship đổi theo khoảng cách thật**.
     > *Câu nói:* "Phí ship bằng 10.000đ cho 2km đầu, cộng 4.000đ mỗi km tiếp theo, rồi nhân hệ số theo gói giao: Ưu tiên ×1.5, Tiêu chuẩn ×1.0, Tiết kiệm ×0.6. Ngoài bán kính 30km thì hệ thống từ chối giao."
   - Đổi **gói giao hàng** → phí đổi theo hệ số.
   - **Áp voucher** `DEMO10K` vừa tạo ở Màn 2 → tiền giảm hiện ra ngay.
     > *Câu nói:* "Voucher vừa tạo bên portal đã có hiệu lực ngay ở app — cùng một cơ sở dữ liệu, không có bước đồng bộ thủ công nào."
8. Chọn **Thanh toán khi nhận hàng (COD)** → **Đặt hàng**.
9. Màn **theo dõi đơn** hiện trạng thái `Chờ xác nhận`. **Để nguyên màn này.**

---

### Màn 4 — Realtime: shop xử lý, khách thấy ngay *(2 phút — điểm nhấn kỹ thuật)*

Chuyển sang tab **Shop Portal**.

1. **Đơn mới vừa nhảy vào danh sách mà không cần F5** (Socket.IO), kèm **tiếng chuông báo đơn** nếu bật loa.
2. Mở **chi tiết đơn** → mã đơn, món kèm topping đã chọn, ghi chú của khách, phí ship, giảm giá, và **lịch sử chuyển trạng thái**.
3. Bấm **Xác nhận** → chỉ ngay sang điện thoại: **trạng thái đổi + thông báo đẩy FCM**.
4. Bấm tiếp **Đang chuẩn bị** → **Đang giao** → **Hoàn thành**, mỗi bước liếc lại điện thoại.

> *Câu nói:* "Trạng thái đi một chiều `pending → confirmed → preparing → delivering → completed`. Backend chỉ chấp nhận đúng bước kế tiếp, nên không thể nhảy từ 'chờ xác nhận' thẳng sang 'hoàn thành' kể cả khi gọi trực tiếp API. Huỷ chỉ được phép khi đơn còn ở `pending` hoặc `confirmed` — đã vào bếp thì không huỷ."

---

### Màn 5 — Đánh giá *(1 phút)*

1. Trên app, ở đơn vừa **Hoàn thành** → **Đánh giá**: 5 sao, nhập nhận xét, **đính kèm 1 ảnh**, gửi.
2. Về **Shop Portal → Đánh giá**: đánh giá vừa gửi đã có mặt, **điểm trung bình của shop được tính lại**.
3. Bấm **Ẩn** một đánh giá → *"Shop chỉ được ẩn khỏi hiển thị, không xoá được đánh giá của khách."*

---

### Màn 6 — Thanh toán VNPay *(2 phút)*

1. Trên app, đặt **đơn thứ hai** (1 món cho nhanh), bước thanh toán chọn **VNPay**.
2. App mở **cổng VNPay Sandbox** → chọn ngân hàng **NCB** → nhập thẻ test:

   | Trường | Giá trị |
   |---|---|
   | Số thẻ | `9704198526191432198` |
   | Tên chủ thẻ | `NGUYEN VAN A` |
   | Ngày phát hành | `07/15` |
   | OTP | `123456` |

3. Thanh toán xong → app quay về, đơn hiện **Đã thanh toán**.
4. Mở **Shop Portal → chi tiết đơn** → `payment_status = paid`.

> *Câu nói:* "Chữ ký `vnp_SecureHash` được kiểm tra lại ở phía server khi VNPay trả về, nên không thể giả kết quả thanh toán bằng cách sửa URL."

**Nếu mạng phòng bảo vệ chập chờn:** bỏ màn này, thay bằng mở một đơn cũ có `payment_method = vnpay, payment_status = paid` trong Shop Portal rồi giải thích luồng bằng lời — trong dữ liệu đã có sẵn hàng trăm đơn như vậy.

---

### Màn 7 — Báo cáo & chốt *(2 phút)*

1. **Shop Portal → Báo cáo doanh thu**, đổi bộ lọc **7 ngày rồi 30 ngày**:

   | Bộ lọc | Doanh thu | Đơn | So kỳ trước | Tỷ lệ huỷ |
   |---|---|---|---|---|
   | 7 ngày | 5.512.200đ | 47 | −14.7% | 10.4% |
   | 30 ngày | 26.627.000đ | 222 | −6.5% | 10.8% |

   Kèm biểu đồ doanh thu theo ngày và Top 10 sản phẩm bán chạy.

   > ⚠️ **Đừng bấm mốc 90 ngày.** Dữ liệu chỉ có 60 ngày nên cột "so với kỳ trước" sẽ trống. Nếu lỡ bấm, giải thích luôn: *"Kỳ trước không có dữ liệu nên hệ thống trả về rỗng thay vì hiện +100% gây hiểu nhầm."* — đúng như code đang xử lý.

2. Quay lại **Admin Dashboard** → số liệu toàn sàn đã cộng thêm hai đơn vừa tạo.
3. Chốt: *"Hệ thống phục vụ đủ ba vai trò — khách hàng, chủ cửa hàng, quản trị sàn — trên cùng một nền tảng dữ liệu, có realtime, thông báo đẩy và thanh toán online."*

---

## 5. Câu hỏi hội đồng hay hỏi + gợi ý trả lời

**H: Vì sao chọn MongoDB mà không dùng SQL?**
Dữ liệu sản phẩm có cấu trúc không đều — mỗi món số biến thể và topping khác nhau. Đơn hàng cần **lưu snapshot** tên món, giá và tuỳ chọn tại thời điểm đặt, để sau này shop đổi giá thì hoá đơn cũ không bị sai. Ngoài ra việc lưu toạ độ dạng GeoJSON phục vụ tìm cửa hàng gần cũng thuận tự nhiên hơn.

**H: Vì sao đơn hàng lưu lại cả tên và giá sản phẩm — dữ liệu trùng lặp?**
Đây là chủ ý. Nếu chỉ lưu `product_id`, khi shop đổi giá hoặc xoá món thì hoá đơn cũ sẽ hiển thị sai. Snapshot đảm bảo **hoá đơn là bất biến**, đúng nguyên tắc kế toán.

**H: Xác thực và bảo mật thế nào?**
Firebase Authentication cấp ID Token; backend xác minh bằng Firebase Admin SDK. Web portal đổi token lấy **session cookie `httpOnly`** để JavaScript phía client không đọc được, chống XSS đánh cắp token. Ngoài ra mỗi lần vào portal đều **kiểm tra lại trạng thái tài khoản trong DB**, vì admin khoá tài khoản thì Firebase vẫn coi cookie cũ là hợp lệ.

**H: Làm sao chống hai người đặt cùng lúc làm tồn kho bị âm?**
Tồn kho trừ bằng thao tác nguyên tử `$inc` kèm điều kiện `stock_quantity >= số lượng`. Không đủ hàng thì phép cập nhật không khớp document nào và đơn bị từ chối. Khi huỷ đơn thì hoàn kho, và có cột `stock_restored_at` làm cờ **chống hoàn kho hai lần** nếu khách và shop cùng bấm huỷ.

**H: Realtime hoạt động ra sao?**
Socket.IO. Chủ shop tham gia room `shop_<id>`, khách tham gia room riêng theo `user_id`. Khi đơn đổi trạng thái, server phát sự kiện vào đúng room; song song đó gửi FCM để khách nhận thông báo cả khi đã thoát app.

**H: Vì sao ràng buộc một đơn chỉ một cửa hàng?**
Phí ship và thời gian chuẩn bị thuộc về từng cửa hàng, gộp nhiều shop vào một đơn thì không tính được.

**H: Nếu VNPay báo thành công nhưng app mất mạng đúng lúc đó thì sao?**
Hệ thống hiện thực **hai đường xác nhận độc lập**: **Return URL** (trình duyệt khách quay về) và **IPN** (VNPay gọi thẳng vào server, không phụ thuộc thiết bị khách). Trạng thái ghi qua bảng `payment_sessions` và thao tác ghi là **idempotent** — nếu cả hai đường cùng về, đường thứ hai chỉ trả `Order already confirmed` chứ không xử lý lại. *(Nói thêm nếu bị truy: môi trường demo chạy local nên chưa đăng ký IPN URL công khai với cổng sandbox, thực tế đang chạy bằng Return URL — code IPN đã có sẵn.)*

**H: Shop mới đăng ký thì ai duyệt?**
Trả lời thẳng: schema đã có trạng thái `pending / active / inactive / banned` và **phía khách hàng đã chặn đúng** — chỉ cửa hàng `active` mới xuất hiện. Nhưng **màn hình duyệt bên Admin Portal em chưa làm kịp**, hiện shop đăng ký được tạo thẳng ở trạng thái `active`. Phần backend đã sẵn sàng, chỉ cần bổ sung nút đổi trạng thái.

**H: Sao app chỉ hiện 2 cửa hàng trong khi hệ thống có 5?**
App chỉ hiện cửa hàng trong bán kính 10km quanh địa chỉ đang chọn; ba cơ sở còn lại ở Đà Nẵng nên bị lọc ra. Có thể kiểm chứng ngay bằng cách đổi sang một địa chỉ ở Đà Nẵng.

**H: Hệ thống còn thiếu gì / hướng phát triển?**
Trả lời thật, đừng nói "không thiếu gì": chưa có ứng dụng riêng cho tài xế (schema đã có role `driver`), chưa có chat giữa khách và shop, chưa có gợi ý món bằng học máy, chưa có màn duyệt shop cho admin. MongoDB đang chạy một node nên chưa dùng được transaction đa document — đã xử lý bằng ghi tuần tự kèm rollback thủ công.

---

## 6. Phương án dự phòng

### 6.1. Không kết nối được MongoDB — rủi ro cao nhất

`.env` trỏ tới Mongo trên **máy khác qua ZeroTier** (`10.144.195.81:27018`). Máy đó không bật thì backend chết ngay khi khởi động, và **toàn bộ dữ liệu demo nằm ở đó**.

**Làm ngay tối nay — sao lưu về máy demo:**

1. Cài **MongoDB Community Server** (bản Windows MSI, chọn "Install MongoDB as a Service" → tự chạy ở `localhost:27017`) và **MongoDB Database Tools**.
2. Sao chép dữ liệu về máy:

   ```bash
   mongodump --uri="mongodb://admin:password123@10.144.195.81:27018/Database_TuhuBread?authSource=admin" --out=./backup_demo
   ```

   ```bash
   mongorestore --uri="mongodb://localhost:27017" --nsFrom="Database_TuhuBread.*" --nsTo="Database_TuhuBread.*" ./backup_demo
   ```

3. Nếu sáng mai máy kia không lên, chỉ cần đổi một dòng trong `be/.env` rồi khởi động lại backend:

   ```
   MONGOOSE_URL=mongodb://localhost:27017/Database_TuhuBread
   ```

*(Nếu không kịp cài Database Tools: cài Mongo local, đổi `MONGOOSE_URL` sang localhost rồi chạy `npm run seed:demo` — script sẽ dựng lại lịch sử đơn, nhưng shop/sản phẩm gốc của bạn thì không có, nên cách dump/restore ở trên vẫn tốt hơn.)*

### 6.2. Điện thoại không gọi được API

Kiểm tra theo thứ tự: (1) `tuhubread/env` đúng IP máy chạy backend chưa — (2) điện thoại và máy tính cùng Wi-Fi chưa — (3) Firewall Windows đã mở port 3000 chưa. Dự phòng cuối: phát 4G từ điện thoại, cho laptop nối vào, rồi lấy IP mới.

### 6.3. App crash giữa chừng

Không sửa code trước hội đồng. Nói "em xin phép khởi động lại ứng dụng", mở lại và tiếp tục từ Shop Portal — phần lớn nghiệp vụ vẫn trình bày được trên web.

### 6.4. Quay sẵn video dự phòng

Tối nay quay một lượt chạy trọn vẹn kịch bản này (2–3 phút, có tiếng). Nếu tại chỗ hỏng mạng hoàn toàn, mở video ra và thuyết minh — vẫn hơn nhiều so với đứng chờ.

---

## 7. Nhắc cuối

- Nói **nghiệp vụ trước, kỹ thuật sau**. Hội đồng quan tâm "hệ thống giải quyết vấn đề gì" hơn là tên thư viện.
- Mỗi khi bấm một nút, **nói trước bạn kỳ vọng thấy gì** rồi mới bấm. Kết quả đúng như vừa nói thì sức thuyết phục gấp đôi.
- Không đọc code trên máy chiếu trừ khi được hỏi. Nếu bị hỏi, mở đúng một file đã biết trước: `be/services/order.service.js` (tạo đơn + trừ kho) hoặc `be/utils/deliveryFee.util.js` (công thức phí ship).
- Sạc đầy điện thoại và laptop. Mang theo cáp USB.
