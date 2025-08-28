document.addEventListener("DOMContentLoaded", function () {
  const createBtn = document.querySelector("input[type='submit'][name='commit'][value='Create']");
  const genBtn = document.querySelector("input[type='submit'][name='commit'][value='Gen ✨']");

  if (createBtn && genBtn) {
    genBtn.style.marginRight = "5px"; 
    createBtn.parentNode.insertBefore(genBtn, createBtn);
  }
});
