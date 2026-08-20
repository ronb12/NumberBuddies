(function () {
  function clickNextOrSave() {
    var modal = document.querySelector("[role=dialog]");
    if (!modal) return "no modal";
    var btn = [...modal.querySelectorAll("button")].find(function (b) {
      var t = b.textContent.trim();
      return t === "Next" || t === "Save" || t === "Done";
    });
    if (btn) {
      btn.click();
      return btn.textContent.trim();
    }
    return "no btn";
  }

  function selectAllNo() {
    var modal = document.querySelector("[role=dialog]");
    if (!modal) return 0;
    var radios = [...modal.querySelectorAll('input[type="radio"]')];
    var groups = {};
    radios.forEach(function (r) {
      if (!groups[r.name]) groups[r.name] = [];
      groups[r.name].push(r);
    });
    var count = 0;
    Object.keys(groups).forEach(function (name) {
      var no =
        groups[name].find(function (r) {
          return r.value === "false" || r.value === "NONE" || r.value === "0";
        }) || groups[name][0];
      if (no && !no.checked) {
        no.click();
        no.checked = true;
        no.dispatchEvent(new Event("change", { bubbles: true }));
        count++;
      }
    });

    var selects = [...modal.querySelectorAll("select")];
    selects.forEach(function (sel) {
      for (var i = 0; i < sel.options.length; i++) {
        var text = sel.options[i].text.toLowerCase();
        if (
          text.includes("none") ||
          text.includes("no") ||
          text.includes("infrequent") === false
        ) {
          if (text.includes("none") || text === "no") {
            sel.selectedIndex = i;
            sel.dispatchEvent(new Event("change", { bubbles: true }));
            break;
          }
        }
      }
    });
    return count;
  }

  selectAllNo();
  return clickNextOrSave();
})();
