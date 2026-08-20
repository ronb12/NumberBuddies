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

  var primary = document.getElementById("primaryCategory");
  if (primary) {
    for (var i = 0; i < primary.options.length; i++) {
      if (primary.options[i].text === "Education") {
        primary.selectedIndex = i;
        break;
      }
    }
    primary.dispatchEvent(new Event("change", { bubbles: true }));
  }

  var saveBtn = [...document.querySelectorAll("button")].find(function (b) {
    return b.textContent.trim() === "Save";
  });
  if (saveBtn) saveBtn.click();

  return JSON.stringify({
    subtitle: document.getElementById("subtitle")?.value || "",
    category: primary?.options[primary.selectedIndex]?.text || "",
  });
})();
