/**
 * Bộ chọn "Tỉnh/Thành phố" + "Phường/Xã" cho form địa chỉ shop — thay cho
 * việc bắt chủ shop tự dò trên bản đồ để ghim vị trí (rất khó dùng, nhất là
 * trên di động). Dùng danh mục hành chính công khai provinces.open-api.vn
 * (đã cập nhật cấu trúc 34 tỉnh/thành, 2 cấp sau sáp nhập 2025 — không còn
 * quận/huyện) để đổ 2 dropdown, sau đó geocode XUÔI (tên → toạ độ) qua
 * Nominatim để lấy toạ độ tâm phường/xã đã chọn — không cần tự có sẵn dữ
 * liệu toạ độ cho hàng nghìn phường/xã.
 *
 * Dùng chung cho cả register.ejs và settings.ejs — mỗi trang tự quyết định
 * việc di chuyển marker/field toạ độ ra sao qua callback onLocationResolved.
 *
 * initVnAddressPicker({
 *   provinceSelectId, wardSelectId,
 *   onLocationResolved: (lat, lng, label) => {...},  // label: "Phường X, Tỉnh Y"
 *   onError: (err) => {...},                          // tuỳ chọn
 * })
 */
(function () {
  const PROVINCES_API = "https://provinces.open-api.vn/api/v2";
  const NOMINATIM_SEARCH = "https://nominatim.openstreetmap.org/search";

  async function fetchProvinces() {
    const res = await fetch(`${PROVINCES_API}/p/`);
    if (!res.ok) throw new Error("Không tải được danh sách tỉnh/thành");
    return res.json();
  }

  async function fetchWards(provinceCode) {
    const res = await fetch(`${PROVINCES_API}/p/${provinceCode}?depth=2`);
    if (!res.ok) throw new Error("Không tải được danh sách phường/xã");
    const data = await res.json();
    return data.wards || [];
  }

  async function geocode(query) {
    const url = `${NOMINATIM_SEARCH}?format=json&q=${encodeURIComponent(query)}&countrycodes=vn&accept-language=vi&limit=1`;
    const res = await fetch(url);
    if (!res.ok) throw new Error("Không tra được toạ độ cho khu vực này");
    const results = await res.json();
    return results[0] || null;
  }

  window.initVnAddressPicker = function initVnAddressPicker({
    provinceSelectId,
    wardSelectId,
    onLocationResolved,
    onError,
  }) {
    const provinceSelect = document.getElementById(provinceSelectId);
    const wardSelect = document.getElementById(wardSelectId);
    if (!provinceSelect || !wardSelect) return;

    let provinces = [];

    function resetWardSelect(placeholder) {
      wardSelect.innerHTML = `<option value="">${placeholder}</option>`;
      wardSelect.disabled = true;
    }

    resetWardSelect("Chọn tỉnh/thành phố trước");

    fetchProvinces()
      .then((list) => {
        provinces = list;
        provinceSelect.innerHTML =
          '<option value="">-- Chọn tỉnh/thành phố --</option>' +
          list.map((p) => `<option value="${p.code}">${p.name}</option>`).join("");
      })
      .catch((err) => {
        console.error("[vn_address_picker] load provinces failed", err);
        if (onError) onError(err);
      });

    provinceSelect.addEventListener("change", async () => {
      const code = provinceSelect.value;
      if (!code) {
        resetWardSelect("Chọn tỉnh/thành phố trước");
        return;
      }
      resetWardSelect("Đang tải...");
      try {
        const wards = await fetchWards(code);
        wardSelect.innerHTML =
          '<option value="">-- Chọn phường/xã --</option>' +
          wards.map((w) => `<option value="${w.code}">${w.name}</option>`).join("");
        wardSelect.disabled = false;
      } catch (err) {
        console.error("[vn_address_picker] load wards failed", err);
        resetWardSelect("Lỗi tải phường/xã, thử lại");
        if (onError) onError(err);
      }
    });

    wardSelect.addEventListener("change", async () => {
      const provinceCode = provinceSelect.value;
      const wardCode = wardSelect.value;
      if (!provinceCode || !wardCode) return;

      const province = provinces.find((p) => String(p.code) === String(provinceCode));
      const wardName = wardSelect.options[wardSelect.selectedIndex].text;
      if (!province) return;

      const label = `${wardName}, ${province.name}`;
      try {
        const result = await geocode(`${label}, Việt Nam`);
        if (!result) {
          if (onError) onError(new Error("Không tìm được toạ độ cho khu vực này — hãy ghim tay trên bản đồ"));
          return;
        }
        onLocationResolved(parseFloat(result.lat), parseFloat(result.lon), label);
      } catch (err) {
        console.error("[vn_address_picker] geocode failed", err);
        if (onError) onError(err);
      }
    });
  };
})();
