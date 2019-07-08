function teamTile(member) {
  console.log(member);
  return '<div class="team-tile">' +
      '<a href="' + member.author.html_url + '">' +
        '<img src="' + member.author.avatar_url + '" />' +
        '<p class="team-tile-login">' +
          member.author.login +
        '</p>' +
      '</a>' +
    '</div>';
}

function fetchTeam(json, team, div) {
  let el = document.querySelector(div);
  el.innerHTML = team.map(function (m) {
    let index = json.findIndex(function(e) {
      return e.author.login === m
    });
    return teamTile(json.splice(index, 1)[0]);
  }).join('');
}

function fetchContributors(json) {
  let el = document.querySelector('#contributors-list');
  el.innerHTML = json.reverse().map(function (c) {
    return '<span class="contributor"><a href="' + c.author.html_url + '">' + c.author.login + '</a></span>';
  }).join('<b> &#183; </b>');
}

function hideLoader() {
  let el = document.querySelector('#loader');
  el.classList.add('hidden');
}

function showTeam() {
  let el = document.querySelector('#team-content');
  el.classList.remove('hidden');
}

fetch('https://api.github.com/repos/lostisland/faraday/stats/contributors')
  .then(function (response) {
    response.json().then(function (json) {
      fetchTeam(json, ['technoweenie', 'iMacTia', 'olleolleolle'], '#active-maintainers-list');
      fetchTeam(json, ['mislav', 'sferik'], '#historical-team-list');
      fetchContributors(json);
      hideLoader();
      showTeam();
    });
  });