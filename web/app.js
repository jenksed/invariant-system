(function () {
  var GOALS = ['Understand this repository'];
  var goalsEl = document.getElementById('goals');
  GOALS.forEach(function (g) {
    var li = document.createElement('li');
    li.textContent = g;
    goalsEl.appendChild(li);
  });
  var btn = document.getElementById('run-btn');
  var repoEl = document.getElementById('repo');
  var resultCard = document.getElementById('result-card');
  var reconCard = document.getElementById('recon-card');
  var resultEl = document.getElementById('result');
  var reconEl = document.getElementById('recon');

  // The web surface is launched from the repo we are running against.
  // We default to the current working directory (the loadout repo itself
  // is fine for a demo, but the basic-user path expects a real target).
  repoEl.value = window.location.pathname.indexOf('loadout') === -1 ? '' : '';

  btn.addEventListener('click', function () {
    btn.disabled = true;
    var body = { goal: 'Understand this repository', repository: repoEl.value || '.' };
    fetch('/run', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    })
      .then(function (r) {
        return r.json().then(function (j) {
          return { ok: r.ok, body: j };
        });
      })
      .then(function (out) {
        if (!out.ok) {
          resultEl.textContent =
            'Error: ' + (out.body && out.body.error ? out.body.error : 'unknown');
          resultCard.hidden = false;
          return;
        }
        var view = out.body.view;
        resultEl.textContent = formatView(view);
        reconEl.innerHTML = '';
        (out.body.reconNotes || []).forEach(function (n) {
          var li = document.createElement('li');
          li.textContent = n;
          reconEl.appendChild(li);
        });
        resultCard.hidden = false;
        reconCard.hidden = false;
      })
      .catch(function (err) {
        resultEl.textContent = 'Network error: ' + err.message;
        resultCard.hidden = false;
      })
      .finally(function () {
        btn.disabled = false;
      });
  });

  function formatView(view) {
    var lines = [];
    lines.push('=== Loadout Result View (SIMULATED) ===');
    lines.push('Work ID:        ' + view.workId);
    lines.push('Run ID:         ' + view.runId);
    lines.push('Status:         ' + view.status);
    lines.push('Simulated:      ' + (view.simulated ? 'yes' : 'no'));
    lines.push('Sim reason:     ' + view.simulatedReason);
    lines.push('');
    lines.push('Authority:');
    lines.push('  requested: ' + (view.authority.requested.join(', ') || '(none)'));
    lines.push('  granted:   ' + (view.authority.granted.join(', ') || '(none)'));
    lines.push('  denied:    ' + (view.authority.denied.join(', ') || '(none)'));
    lines.push('');
    lines.push('Evidence (each kind=simulated):');
    view.evidence.forEach(function (e) {
      lines.push('  - ' + e.id + ' [' + e.kind + '] digest=' + e.stateDigest);
      if (e.description) lines.push('      ' + e.description);
    });
    lines.push('');
    lines.push('Acceptance readiness:');
    lines.push('  ready:   ' + view.acceptanceReadiness.ready);
    view.acceptanceReadiness.reasons.forEach(function (r) {
      lines.push('  reason:  ' + r);
    });
    lines.push('');
    lines.push('Summary:');
    lines.push('  ' + view.summary);
    return lines.join('\n');
  }
})();
