(function () {
  function setVal(id, value) {
    var el = document.getElementById(id);
    if (!el) return false;
    el.scrollIntoView({ block: "center" });
    el.focus();
    el.value = value;
    el.dispatchEvent(new Event("input", { bubbles: true }));
    el.dispatchEvent(new Event("change", { bubbles: true }));
    return true;
  }

  var description =
    "Number Buddies is a friendly math coach for ages 6\u20138. Kids practice addition, subtraction, multiplication, and division in short rounds with visual helpers, read-aloud support, and stars to celebrate progress.\n\n" +
    "FEATURES\n" +
    "\u2022 Four core operations with levels that grow with your child\n" +
    "\u2022 Mixed Review and Math Challenges for daily practice\n" +
    "\u2022 Explore Math: fractions, decimals, time, money, geometry, graphs, and word problems\n" +
    "\u2022 Picture helpers and step-by-step paper work explanations\n" +
    "\u2022 Parent progress report with PDF export\n" +
    "\u2022 No accounts, no ads, and no tracking \u2014 progress stays on device\n\n" +
    "Number Buddies is designed for Grades 1\u20132 and supports iPhone and iPad.";

  setVal(
    "promotionalText",
    "Short, visual math practice for ages 6\u20138 \u2014 no ads, no accounts, progress stays on device."
  );
  setVal("description", description);

  var saveBtn = [...document.querySelectorAll("button")].find(function (b) {
    return b.textContent.trim() === "Save";
  });
  if (saveBtn) saveBtn.click();

  return JSON.stringify({
    promotionalText: document.getElementById("promotionalText").value,
    description: document.getElementById("description").value.slice(0, 80),
  });
})();
