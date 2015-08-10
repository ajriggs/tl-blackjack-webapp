$(document).ready(function() {
    $(document).on('click', 'form#hit button', function() {
        $.ajax({
            type: 'POST',
            url: '/game/hit_player',
        }).done(function(msg){
            $('#game').replaceWith(msg);
        });
    return false;
    });

    $(document).on('click', 'form#stay button', function() {
        $.ajax({
            type: 'POST',
            url: '/game/stay',
        }).done(function(msg){
            $('#game').replaceWith(msg);
        });
    return false;
    });

    $(document).on('click', 'form#hit_dealer button', function() {
        $.ajax({
            type: 'POST',
            url: '/game/hit_dealer',
        }).done(function(msg){
            $('#game').replaceWith(msg);
        });
    return false;
    });

});
