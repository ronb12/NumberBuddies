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
  setVal(
    "keywords",
    "math,kids,addition,subtraction,multiplication,division,education,grade 1,grade 2,learning"
  );
  setVal("supportUrl", "https://github.com/ronb12/NumberBuddies");
  setVal("copyright", "2026 Bradley Virtual Solutions, LLC");
  setVal("contactFirstName", "Ronell");
  setVal("contactLastName", "Bradley");
  setVal("contactPhone", "803-555-0100");
  setVal("contactEmail", "ronellbradley@gmail.com");
  setVal(
    "notes",
    "Number Buddies is a kids math practice app with no login. Open the app and tap any operation card or Explore Math to begin. Parent progress report is under Settings > Progress report. No demo account is required."
  );

  var signIn = document.getElementById("appStoreReviewDetails_demoAccountRequired");
  if (signIn && signIn.checked) signIn.click();

  var manual = document.getElementById("MANUAL");
  if (manual) manual.click();

  return JSON.stringify({
    description: document.getElementById("description").value.slice(0, 40),
    keywords: document.getElementById("keywords").value,
    support: document.getElementById("supportUrl").value,
    signIn: document.getElementById("appStoreReviewDetails_demoAccountRequired").checked,
  });
})();
