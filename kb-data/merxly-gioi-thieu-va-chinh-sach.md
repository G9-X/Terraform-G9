# Merxly — Giới Thiệu Nền Tảng & Chính Sách

## 1. Giới thiệu về Merxly

Merxly là nền tảng thương mại điện tử (e-commerce marketplace) kết nối người mua và người bán. Merxly hoạt động như một sàn giao dịch trung gian, cho phép các cửa hàng (Store) đăng ký và bán sản phẩm, trong khi người mua (Customer) có thể tìm kiếm, so sánh và mua sắm từ nhiều cửa hàng khác nhau trên cùng một nền tảng.

Website: https://app.group9.id.vn

### Tính năng chính:
- **Tìm kiếm sản phẩm**: Người dùng có thể tìm kiếm theo từ khóa, lọc theo danh mục
- **Giỏ hàng (Cart)**: Thêm sản phẩm từ nhiều cửa hàng vào cùng một giỏ hàng
- **Wishlist**: Lưu sản phẩm yêu thích để mua sau
- **Đánh giá sản phẩm (Review)**: Người mua có thể đánh giá sản phẩm bằng sao và viết nhận xét
- **Theo dõi đơn hàng (Track Order)**: Xem trạng thái đơn hàng theo thời gian thực
- **So sánh sản phẩm (Compare)**: So sánh các sản phẩm khác nhau
- **Hỗ trợ khách hàng (Customer Support)**: Liên hệ hỗ trợ
- **Trợ lý AI**: Chatbot AI hỗ trợ tìm kiếm sản phẩm và trả lời câu hỏi

---

## 2. Hệ thống danh mục sản phẩm

Merxly tổ chức sản phẩm theo hệ thống danh mục phân cấp (hierarchical categories):
- Danh mục cha (Parent Category): ví dụ "Thời trang", "Điện tử", "Gia dụng"
- Danh mục con (Sub Category): ví dụ "Áo thun", "Điện thoại", "Nồi cơm điện"

Mỗi sản phẩm thuộc về một danh mục cụ thể và một cửa hàng cụ thể.

---

## 3. Sản phẩm trên Merxly

Mỗi sản phẩm trên Merxly có các thông tin sau:
- **Tên sản phẩm (Name)**
- **Mô tả (Description)**
- **Giá**: Hiển thị khoảng giá từ MinPrice đến MaxPrice (tùy theo biến thể)
- **Tồn kho (TotalStock)**: Tổng số lượng còn lại
- **Đánh giá trung bình (AverageRating)**: Thang điểm sao
- **Số lượng đánh giá (ReviewCount)**
- **Số lượng đã bán (TotalSold)**
- **Hình ảnh sản phẩm**: Hình ảnh chính và hình ảnh các biến thể

### Biến thể sản phẩm (Product Variants)
Mỗi sản phẩm có thể có nhiều biến thể, ví dụ:
- Áo thun có biến thể: Size S/M/L/XL, Màu Đen/Trắng/Đỏ
- Điện thoại có biến thể: 128GB/256GB/512GB

Mỗi biến thể có:
- **Tên biến thể**
- **Mã SKU** (Stock Keeping Unit)
- **Giá riêng**
- **Số lượng tồn kho riêng**
- **Kích thước, cân nặng** (nếu có)
- **Hình ảnh riêng**

### Thuộc tính sản phẩm (Product Attributes)
Sản phẩm có thể có các thuộc tính tùy chỉnh như:
- Màu sắc (Color)
- Kích thước (Size)
- Chất liệu (Material)
- Dung lượng (Capacity)

---

## 4. Cửa hàng (Store) trên Merxly

### Đăng ký cửa hàng
Bất kỳ ai cũng có thể đăng ký mở cửa hàng trên Merxly bằng cách:
1. Tạo tài khoản trên Merxly
2. Điền thông tin cửa hàng: tên cửa hàng, mô tả, email, số điện thoại
3. Cung cấp thông tin chủ sở hữu: tên, email, số điện thoại
4. Upload giấy tờ: CMND/CCCD (mặt trước + mặt sau), Giấy phép kinh doanh
5. Cung cấp mã số thuế (Tax Code)
6. Chờ admin xét duyệt (Verification)

### Thông tin cửa hàng
- **Tên cửa hàng (StoreName)**
- **Mô tả (Description)**
- **Logo và Banner**
- **Email và Số điện thoại liên hệ**
- **Website** (nếu có)
- **Địa chỉ cửa hàng (StoreAddress)**
- **Tỷ lệ hoa hồng (CommissionRate)**: Phần trăm Merxly thu trên mỗi đơn hàng

### Thanh toán cho cửa hàng
Merxly tích hợp **Stripe Connect** để thanh toán cho cửa hàng:
- Mỗi cửa hàng có tài khoản Stripe Connect riêng
- Sau khi đơn hàng hoàn thành, tiền sẽ được chuyển cho cửa hàng (trừ hoa hồng)

---

## 5. Quy trình mua hàng

### Bước 1: Tìm và chọn sản phẩm
- Tìm kiếm theo từ khóa hoặc duyệt theo danh mục
- Xem chi tiết sản phẩm: mô tả, giá, đánh giá, hình ảnh
- Chọn biến thể (size, màu, etc.)

### Bước 2: Thêm vào giỏ hàng
- Thêm sản phẩm vào giỏ hàng
- Có thể thêm sản phẩm từ nhiều cửa hàng khác nhau

### Bước 3: Thanh toán (Checkout)
- Xác nhận giỏ hàng
- Nhập địa chỉ giao hàng
- Thanh toán qua **Stripe** (thẻ tín dụng/debit)

### Bước 4: Theo dõi đơn hàng
Mỗi đơn hàng có thể chứa nhiều "sub-order" (đơn con) từ các cửa hàng khác nhau. Trạng thái đơn hàng:
- **Pending**: Chờ xác nhận
- **Confirmed**: Đã xác nhận
- **Processing**: Đang xử lý
- **Delivering**: Đang giao hàng
- **Shipped**: Đã giao cho đơn vị vận chuyển
- **Completed**: Hoàn thành
- **Cancelled**: Đã hủy
- **Refunded**: Đã hoàn tiền
- **Failed**: Thất bại

---

## 6. Thanh toán

Merxly sử dụng **Stripe** làm cổng thanh toán chính:
- Hỗ trợ thanh toán bằng thẻ tín dụng và thẻ ghi nợ (debit card)
- Đơn vị tiền tệ: USD
- Trạng thái thanh toán: Pending → Processing → Succeeded / Failed
- Hỗ trợ hoàn tiền (Refund) một phần hoặc toàn bộ
- Hóa đơn điện tử (Receipt) được tạo tự động bởi Stripe

---

## 7. Chính sách của Merxly

### 7.1. Chính sách đăng ký cửa hàng
- Cửa hàng phải cung cấp đầy đủ giấy tờ pháp lý (CMND, Giấy phép kinh doanh)
- Admin Merxly sẽ xét duyệt trước khi cửa hàng được hoạt động
- Cửa hàng bị từ chối sẽ nhận được lý do cụ thể (RejectionReason)

### 7.2. Chính sách hoa hồng
- Merxly thu phí hoa hồng (CommissionRate) trên mỗi đơn hàng thành công
- Tỷ lệ hoa hồng được thiết lập cho từng cửa hàng
- Tiền hoa hồng được trừ tự động khi chuyển tiền cho cửa hàng (Store Transfer)

### 7.3. Chính sách hoàn trả & hoàn tiền
- Người mua có thể yêu cầu hoàn tiền nếu sản phẩm không đúng mô tả
- Hỗ trợ hoàn tiền toàn phần hoặc một phần (PartiallyRefunded)
- Trạng thái hoàn tiền: Pending → Approved → Completed / Rejected

### 7.4. Chính sách đánh giá
- Chỉ người mua đã mua sản phẩm mới có thể đánh giá
- Đánh giá bao gồm: điểm sao (Rating) và nội dung nhận xét (Comment)
- Người mua có thể đính kèm hình ảnh/video khi đánh giá
- Đánh giá giúp người mua khác tham khảo trước khi mua

### 7.5. Chính sách tài khoản
- Mỗi người dùng có thể có vai trò: Customer (khách hàng), Store Owner (chủ cửa hàng), Admin
- Người dùng có thể quản lý thông tin cá nhân, địa chỉ giao hàng
- Hỗ trợ đăng nhập bảo mật với JWT token

---

## 8. Hỗ trợ khách hàng

Nếu bạn cần hỗ trợ, vui lòng:
- Sử dụng chatbot AI trên website để hỏi đáp nhanh
- Liên hệ qua email hỗ trợ
- Sử dụng tính năng "Need Help" trên thanh menu
- Xem phần Customer Support trên website

---

## 9. Câu hỏi thường gặp (FAQ)

**Q: Làm sao để tìm sản phẩm trên Merxly?**
A: Bạn có thể sử dụng thanh tìm kiếm ở đầu trang, duyệt theo danh mục "All Category", hoặc hỏi trợ lý AI của chúng tôi.

**Q: Tôi có thể mua hàng từ nhiều cửa hàng cùng lúc không?**
A: Có! Bạn có thể thêm sản phẩm từ nhiều cửa hàng vào cùng một giỏ hàng. Mỗi cửa hàng sẽ xử lý đơn hàng riêng (sub-order).

**Q: Phương thức thanh toán nào được hỗ trợ?**
A: Merxly hỗ trợ thanh toán qua thẻ tín dụng và thẻ ghi nợ thông qua Stripe.

**Q: Làm sao để theo dõi đơn hàng?**
A: Vào mục "Track Order" trên menu hoặc xem trong "Order History" trong tài khoản của bạn.

**Q: Tôi muốn hoàn trả sản phẩm thì làm thế nào?**
A: Liên hệ với cửa hàng hoặc sử dụng tính năng hoàn tiền trong chi tiết đơn hàng.

**Q: Làm sao để mở cửa hàng trên Merxly?**
A: Click vào "Selling on Merxly" trên thanh menu, điền thông tin và giấy tờ, chờ admin xét duyệt.

**Q: Phí bán hàng trên Merxly là bao nhiêu?**
A: Merxly thu phí hoa hồng trên mỗi đơn hàng thành công. Tỷ lệ cụ thể sẽ được thông báo khi đăng ký cửa hàng.
