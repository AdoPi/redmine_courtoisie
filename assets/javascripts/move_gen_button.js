document.addEventListener("DOMContentLoaded", function () {
  const allSubmitButtons = Array.from(document.querySelectorAll("input[type='submit'][name='commit']"));
  const genBtn = allSubmitButtons.find(btn => btn.value === "Gen ✨");

  const firstOtherBtn = allSubmitButtons.find(btn => btn !== genBtn);

  if (genBtn && firstOtherBtn) {
    genBtn.style.marginRight = "5px";
    firstOtherBtn.parentNode.insertBefore(genBtn, firstOtherBtn);
  }
});
