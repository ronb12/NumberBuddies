(function () {
  function setVal(id, value) {
    var el = document.getElementById(id);
    if (!el) return false;
    el.focus();
    el.value = value;
    el.dispatchEvent(new Event("input", { bubbles: true }));
    el.dispatchEvent(new Event("change", { bubbles: true }));
    return true;
  }

  setVal("subtitle", "Math practice for ages 6\u20138");

  var saveBtn = [...document.querySelectorAll("button")].find(function (b) {
    return b.textContent.trim() === "Save";
  });
  if (saveBtn) saveBtn.click();

  return JSON.stringify({
    subtitle: document.getElementById("subtitle")?.value || "",
  });
})();
