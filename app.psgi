use Plack::Builder;
use Plack::App::unAPI;

Plack::App::unAPI->new(
    formats => {
        foo => $app
    } 
);
