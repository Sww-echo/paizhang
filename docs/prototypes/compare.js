/* 牌账 · 原型对照页脚本：5 屏自适应缩放 + A/C 主题切换 */
(function () {
  var body = document.body;
  var stage = document.querySelector('.stage');
  var wrap = document.querySelector('.stagewrap');

  function fit() {
    if (!stage || !wrap) return;
    var n = stage.children.length;
    var gap = 26;
    var total = n * 390 + (n - 1) * gap;
    var avail = Math.min(document.documentElement.clientWidth - 48, 2100);
    var z = Math.min(1, avail / total);
    stage.style.transform = 'translateX(-50%) scale(' + z + ')';
    wrap.style.height = Math.ceil(stage.offsetHeight * z + 8) + 'px';
  }

  // 主题切换（A / C）
  var btns = document.querySelectorAll('[data-set]');
  function setTheme(t) {
    body.setAttribute('data-theme', t);
    for (var i = 0; i < btns.length; i++) {
      btns[i].classList.toggle('on', btns[i].getAttribute('data-set') === t);
    }
    try { localStorage.setItem('pz-theme', t); } catch (e) {}
    fit();
  }
  for (var i = 0; i < btns.length; i++) {
    btns[i].addEventListener('click', function () { setTheme(this.getAttribute('data-set')); });
  }
  document.addEventListener('keydown', function (e) {
    var k = e.key.toLowerCase();
    if (k === 'a' || k === 'c') setTheme(k);
  });

  var saved = null;
  try { saved = localStorage.getItem('pz-theme'); } catch (e) {}
  if (saved === 'a' || saved === 'c') setTheme(saved); else fit();

  window.addEventListener('resize', fit);
  if (document.fonts && document.fonts.ready) document.fonts.ready.then(fit);
})();
