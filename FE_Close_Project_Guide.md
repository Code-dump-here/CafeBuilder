# FE — Hướng dẫn nối luồng đóng hợp tác & đóng dự án

Tài liệu dành cho FE. Mô tả các API mới của luồng: **provider báo xong việc → owner nghiệm thu từng
provider → owner đóng/huỷ dự án**, kèm điều kiện hiện nút và mã lỗi cần bắt.

Base URL: `/api` · Mọi endpoint đều cần header `Authorization: Bearer <accessToken>`.

---

## 1. Đọc nhanh: có gì mới

| Nhóm | Endpoint mới | Ai gọi |
|---|---|---|
| Provider báo xong việc | `POST /api/project-workings/{id}/request-completion` | provider |
| Owner nghiệm thu | `POST /api/project-workings/{id}/complete` | owner |
| Huỷ ngang hợp tác | `POST /api/project-workings/{id}/terminate` | owner **hoặc** provider |
| Owner đóng dự án | `POST /api/project-shop-owners/{id}/complete` | owner |
| Owner huỷ dự án | `POST /api/project-shop-owners/{id}/cancel` | owner |

**3 field mới** trong `ProjectWorkingResponse`: `completionRequestedAt`, `completionRequestNote`,
`isAwaitingAcceptance`.

**5 loại notification mới** — xem mục 6.

### ⚠️ Breaking change cần sửa ở FE

1. **`PUT /api/project-shop-owners/{id}` không nhận `status: "completed"` / `"cancelled"` nữa** →
   trả **409**. Phải chuyển sang gọi `/complete` hoặc `/cancel`.
2. **Mọi thao tác vòng đời nay kiểm tra vai trò** → gọi bằng token sai vai trò trả **401**
   (trước đây token nào cũng gọi được). Nếu FE đang cho cả 2 phía dùng chung một nút thì phải tách.
3. `PUT /api/project-shop-owners/{id}` nay chặn transition sai (vd `briefed → completed`) → **409**.

---

## 2. Vai trò — ai gọi được cái gì

| Hành động | Owner | Provider | Admin |
|---|:---:|:---:|:---:|
| `accept` / `reject` lời mời | ✕ | ✓ | ✓ |
| `request-completion` | ✕ | ✓ | ✓ |
| `complete` (nghiệm thu) | ✓ | ✕ | ✓ |
| `terminate` (huỷ ngang) | ✓ | ✓ | ✓ |
| `project /complete`, `/cancel`, `PUT`, `DELETE` | ✓ (chủ dự án) | ✕ | ✓ |

Sai vai trò → **HTTP 401** kèm message tiếng Việt. BE tự lấy danh tính từ JWT — **FE không gửi
`accountId`/`providerId` trong body**.

---

## 3. Mô hình trạng thái

### Hợp tác (engagement) — `ProjectWorkingResponse.status`

```
requested ──accept──▶ accepted ──complete──▶ completed   (owner nghiệm thu → mở khoá review)
    │                     │
    └──reject──▶ rejected └──terminate──▶ terminated
```

**Quan trọng:** không có trạng thái `"đang chờ nghiệm thu"` trong `status`. Đó là trạng thái **suy ra**:

```js
// status vẫn là "accepted", nhưng provider đã bấm báo xong
const dangChoNghiemThu = pw.isAwaitingAcceptance; // BE đã tính sẵn, dùng thẳng cờ này
```

Tương tự, `"đang thực hiện"` cũng là suy ra: `status === "accepted" && pw.hasConfirmedContract`.

### Dự án — `ProjectShopOwnerResponse.status`

```
briefed ──(tự động khi ký hợp đồng đầu tiên)──▶ in_progress ──▶ completed
   │                                                 │
   └──────────────── cancelled ◀────────────────────┘
```

`in_progress` **FE không set** — BE tự chuyển khi `POST /api/contracts/{id}/confirm-otp` thành công.

---

## 4. Luồng đầy đủ + JSON

### 4.1 Provider báo hoàn thành

```http
POST /api/project-workings/{engagementId}/request-completion
Content-Type: application/json

{ "note": "Đã bàn giao toàn bộ hạng mục, kèm ảnh hiện trường." }
```

`note` optional, tối đa 1000 ký tự. Body rỗng `{}` cũng hợp lệ.

**Điều kiện hiện nút "Báo hoàn thành"** (phía provider):

```js
const showRequestCompletion =
  pw.status === "accepted" &&
  pw.hasConfirmedContract &&
  !pw.isAwaitingAcceptance;   // đã bấm rồi thì đổi thành nhãn "Đang chờ nghiệm thu"
```

BE còn kiểm deliverable đã xong (mục 4.2) — nếu chưa xong sẽ trả **409**, FE hiển thị message trả về.

Gọi lại được nhiều lần khi owner chưa nghiệm thu (cập nhật ghi chú).

**Response 200** — `ProjectWorkingResponse`, các field liên quan:

```json
{
  "id": 12,
  "projectShopOwnerId": 3,
  "projectName": "Cà phê Sương Mai",
  "serviceProviderProfileId": 7,
  "providerDisplayName": "Xưởng nội thất An Phát",
  "contractType": "construction",
  "status": "accepted",
  "hasConfirmedContract": true,
  "completionRequestedAt": "2026-07-28T09:15:00Z",
  "completionRequestNote": "Đã bàn giao toàn bộ hạng mục, kèm ảnh hiện trường.",
  "isAwaitingAcceptance": true,
  "contract": { "id": 5, "status": "confirmed", "...": "..." }
}
```

### 4.2 Điều kiện "việc đã xong" mà BE kiểm

| `contractType` | Điều kiện |
|---|---|
| `design` | Có ≥ 1 bản design ở `approved` (owner đã duyệt qua `POST /api/designs/{id}/approve`) |
| `construction` | Có ≥ 1 `construction_item`, và **mọi** item ở `completed` |
| `both` | Cả hai điều kiện trên |

Bản design `approved` chắc chắn đã qua `submit` nên đã có file đính kèm — không cần kiểm riêng file.

### 4.3 Owner nghiệm thu

```http
POST /api/project-workings/{engagementId}/complete
```

Không có body. **Điều kiện hiện nút "Nghiệm thu"** (phía owner):

```js
const showComplete =
  pw.status === "accepted" &&
  pw.hasConfirmedContract;
// Ưu tiên/nhấn mạnh nút khi pw.isAwaitingAcceptance === true (provider đã báo xong)
```

Owner **được** nghiệm thu chủ động mà không chờ provider bấm — nhưng khi đó BE yêu cầu deliverable
ở 4.2 phải xong, nếu chưa thì **409** với message gợi ý chờ provider báo hoàn thành.

Nói cách khác, BE cho nghiệm thu khi: `provider đã báo xong` **HOẶC** `deliverable đã xong`.

Sau khi 200: `status = "completed"` → **review mở khoá**, FE có thể cho owner gọi `POST /api/reviews`.

### 4.4 Huỷ ngang hợp tác

```http
POST /api/project-workings/{engagementId}/terminate
```

Cả owner lẫn provider gọi được (song phương). Chỉ từ `accepted`. Sau khi huỷ,
`completionRequestedAt` bị xoá về `null`.

```js
const showTerminate = pw.status === "accepted"; // hiện cho cả 2 phía
```

### 4.5 Owner đóng dự án

```http
POST /api/project-shop-owners/{projectId}/complete
```

**Điều kiện hiện nút "Đóng dự án"**:

```js
const engagements = project.providers ?? [];
const conMo      = engagements.filter(e => ["requested", "accepted"].includes(e.status));
const daNghiemThu = engagements.filter(e => e.status === "completed");

const canComplete =
  project.status === "in_progress" &&
  conMo.length === 0 &&
  daNghiemThu.length > 0;
```

Nếu `conMo.length > 0` → hiện gợi ý: *"Còn N hợp tác chưa đóng, hãy nghiệm thu hoặc huỷ trước."*

Side effect: mọi bài đăng của dự án còn `open` tự chuyển `closed`.

### 4.6 Owner huỷ dự án

```http
POST /api/project-shop-owners/{projectId}/cancel
```

Từ `briefed` hoặc `in_progress`. **Không cần đóng engagement trước** — BE tự cascade:

- engagement `requested` → `rejected`
- engagement `accepted` → `terminated`
- bài đăng `open` → `closed`

```js
const canCancel = ["briefed", "in_progress"].includes(project.status);
```

Nên có dialog xác nhận vì hành động này đóng hàng loạt hợp tác.

---

## 5. Bảng mã lỗi

`GlobalExceptionHandler` trả JSON thống nhất, **message tiếng Việt hiển thị thẳng cho user được**.

| HTTP | Khi nào | FE xử lý |
|---|---|---|
| **401** | Sai vai trò (provider bấm nghiệm thu, người lạ thao tác…) hoặc token hỏng | Ẩn nút; nếu vẫn lọt thì toast message trả về |
| **404** | Sai `id` engagement / dự án | Toast + refetch danh sách |
| **409** | Sai transition, thiếu contract `confirmed`, deliverable chưa xong, còn engagement mở | **Toast message trả về** — message đã nêu rõ nguyên nhân và số lượng |
| **400** | Body sai (vd `note` > 1000 ký tự, `status` không hợp lệ) | Validate trước ở form |

Ví dụ vài message 409 thực tế:

```
"Còn 2 engagement chưa đóng (requested/accepted) — nghiệm thu hoặc huỷ ngang từng provider trước khi đóng dự án."
"Còn 3 hạng mục thi công chưa 'completed' — chưa thể báo hoàn thành."
"Chưa có bản design nào được duyệt ('approved') — chưa thể nghiệm thu (hoặc chờ nhà cung cấp bấm báo hoàn thành)."
"Engagement chưa có contract 'confirmed' — chưa bắt đầu thực hiện nên không thể nghiệm thu."
"Không đóng dự án qua PUT — dùng POST /api/project-shop-owners/{id}/complete."
```

---

## 6. Notification

Luồng này tự bắn noti in-app **và** email cho bên liên quan. FE đọc qua API sẵn có:

```http
GET  /api/notifications?accountId={id}&isRead=false&pageNumber=1&pageSize=20
GET  /api/notifications/unread-count?accountId={id}
PATCH /api/notifications/{id}/read
POST /api/notifications/mark-all-read?accountId={id}
```

### Các `type` mới cần render

| `type` | Người nhận | Bắn khi | `referenceType` / `referenceId` |
|---|---|---|---|
| `engagement_completion_requested` | owner | provider bấm báo hoàn thành | `project_provider` / engagementId |
| `engagement_completed` | provider | owner nghiệm thu | `project_provider` / engagementId |
| `engagement_terminated` | bên **còn lại** | một bên huỷ ngang | `project_provider` / engagementId |
| `project_completed` | các provider đã nghiệm thu | owner đóng dự án | `project` / projectId |
| `project_cancelled` | các provider đang hợp tác | owner huỷ dự án | `project` / projectId |

Deep-link theo `referenceType`:

```js
const href = n.referenceType === "project_provider"
  ? `/engagements/${n.referenceId}`
  : n.referenceType === "project"
  ? `/projects/${n.referenceId}`
  : `/notifications/${n.id}`;
```

Lưu ý: `emailSentAt === null` nghĩa là gửi email lỗi nhưng **noti in-app vẫn có** — cứ hiển thị bình thường.

---

## 7. Checklist tích hợp

- [ ] Bỏ mọi chỗ gửi `status: "completed"` / `"cancelled"` qua `PUT /api/project-shop-owners/{id}`
- [ ] Màn hình provider: nút **Báo hoàn thành** + trạng thái *"Đang chờ nghiệm thu"* theo `isAwaitingAcceptance`
- [ ] Màn hình owner: nút **Nghiệm thu** trên từng provider, làm nổi bật khi `isAwaitingAcceptance`
- [ ] Nút **Huỷ ngang** cho cả hai phía khi `status === "accepted"`
- [ ] Màn hình dự án: nút **Đóng dự án** / **Huỷ dự án** theo điều kiện mục 4.5–4.6
- [ ] Bắt 409 → toast message từ BE (không tự chế message)
- [ ] Ẩn nút theo vai trò, đừng dựa vào 401 để chặn
- [ ] Render 5 `type` notification mới + deep-link

---

## 8. Ghi chú cho BE/DevOps

Migration `20260728024059_AddEngagementCompletionRequest` thêm 2 cột nullable vào `project_providers`
(`completion_requested_at`, `completion_request_note`). App tự chạy `Database.MigrateAsync()` lúc
startup và `localhost:5432` trỏ qua cloud-sql-proxy tới **DB dùng chung** — thống nhất với team
trước khi chạy. Chỉ ADD COLUMN nullable nên code cũ đang chạy không vỡ.
