javascript:(function(){var MyDiv1 = document.getElementById('brightcove-video--class-main-video');alert(MyDiv1.getAttribute('data-account'), MyDiv1.getAttribute('data-video-id'));})();

javascript: (function () { var MyDiv1 = document.getElementById('brightcove-video--class-main-video'); var videoid = MyDiv1.getAttribute('data-video-id'); var dataaccount = MyDiv1.getAttribute('data-account'); var videoURL = 'http://players.brightcove.net/' + dataaccount + '/default_default/index.html?videoId=' + videoid; var copiedURL = copy(videoURL); function copy(text) { var input = document.createElement('textarea'); input.innerHTML = text; document.body.appendChild(input); input.select(); var result = document.execCommand('copy'); document.body.removeChild(input); return result; } alert(copiedURL); })();

javascript:(function(){
    var MyDiv1 = document.getElementById('brightcove-video--class-main-video');
    var videoid = MyDiv1.getAttribute('data-video-id');
    var dataaccount = MyDiv1.getAttribute('data-account');
    var videoURL = 'http://players.brightcove.net/' + dataaccount + '/default_default/index.html?videoId='+ videoid;
    var copiedURL = copy(videoURL);
    function copy(text) {
        var input = document.createElement('textarea');
        input.innerHTML = text;
        document.body.appendChild(input);
        input.select();
        var result = document.execCommand('copy');
        document.body.removeChild(input);
        return result;
    }
    alert(copiedURL);
})();

http://players.brightcove.net/dataaccount/default_default/index.html?videoId=videoid