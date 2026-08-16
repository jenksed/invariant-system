(function () {
  var GOALS = ['Understand this repository'];
  var goalsEl = document.getElementById('goals');
  GOALS.forEach(function (g) {
    var li = document.createElement('li');
    li.textContent = g;
    goalsEl.appendChild(li);
  });
  var btn = document.getElementById('run-btn');
  var planBtn = document.getElementById('plan-btn');
  var runPlanBtn = document.getElementById('run-plan-btn');
  var repoEl = document.getElementById('repo');
  var resultCard = document.getElementById('result-card');
  var reconCard = document.getElementById('recon-card');
  var planCard = document.getElementById('plan-card');
  var resultEl = document.getElementById('result');
  var reconEl = document.getElementById('recon');
  var planEl = document.getElementById('plan');
  var planIdEl = document.getElementById('plan-id');
  var lastPlanPath = null;

  repoEl.value = window.location.pathname.indexOf('loadout') === -1 ? '' : '';

  function repo() {
    return repoEl.value || '.';
  }

  function setBusy(button, busy) {
    button.disabled = busy;
  }

  function renderPlan(out) {
    planEl.textContent = out.planText;
    planIdEl.textContent =
      'plan_id=' +
      out.plan.plan_id +
      '  work_envelope_digest=' +
      out.plan.work_envelope_digest +
      '  saved_at=' +
      out.planPath;
    planCard.hidden = false;
    lastPlanPath = out.planPath;
  }

  function renderRun(out) {
    resultEl.textContent = formatView(out.view);
    reconEl.innerHTML = '';
    (out.reconNotes || []).forEach(function (n) {
      var li = document.createElement('li');
      li.textContent = n;
      reconEl.appendChild(li);
    });
    resultCard.hidden = false;
    reconCard.hidden = false;
  }

  function renderError(msg) {
    resultEl.textContent = 'Error: ' + msg;
    resultCard.hidden = false;
  }

  planBtn.addEventListener('click', function () {
    setBusy(planBtn, true);
    var body = { goal: 'Understand this repository', repository: repo() };
    fetch('/plan', {
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
          renderError(out.body && out.body.error ? out.body.error : 'unknown');
          return;
        }
        renderPlan(out.body);
      })
      .catch(function (err) {
        renderError('Network error: ' + err.message);
      })
      .finally(function () {
        setBusy(planBtn, false);
      });
  });

  runPlanBtn.addEventListener('click', function () {
    if (!lastPlanPath) {
      renderError('No plan produced yet. Click Plan first.');
      return;
    }
    setBusy(runPlanBtn, true);
    var body = { planPath: lastPlanPath, repository: repo() };
    fetch('/run-with-plan', {
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
          renderError(out.body && out.body.error ? out.body.error : 'unknown');
          return;
        }
        renderRun(out.body);
      })
      .catch(function (err) {
        renderError('Network error: ' + err.message);
      })
      .finally(function () {
        setBusy(runPlanBtn, false);
      });
  });

  btn.addEventListener('click', function () {
    setBusy(btn, true);
    var body = { goal: 'Understand this repository', repository: repo() };
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
          renderError(out.body && out.body.error ? out.body.error : 'unknown');
          return;
        }
        renderRun(out.body);
      })
      .catch(function (err) {
        renderError('Network error: ' + err.message);
      })
      .finally(function () {
        setBusy(btn, false);
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
