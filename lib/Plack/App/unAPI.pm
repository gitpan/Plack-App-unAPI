use strict;
use warnings;
package Plack::App::unAPI;
{
  $Plack::App::unAPI::VERSION = '0.1';
}
#ABSTRACT: Serve via unAPI

use 5.010;
use parent qw(Plack::Component Exporter);
use Plack::Request;

our @EXPORT = qw(unAPI);

## no critic
sub unAPI(@) { __PACKAGE__->new(@_) }
## use critic

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my $self = bless {@_}, $class;

    foreach (keys %$self) {
        my ($app, $type, %about) = @{$self->{$_}};
        $self->{$_} = { app => $app, type => $type, %about };
    }

    $self;
}

sub call {
    my ($self, $env) = @_;
    my $req    = Plack::Request->new($env);
    my $format = $req->param('format') // '';
    my $id     = $req->param('id') // '';

    # here we could first lookup the resource at the server
    # and sent 404 if no known format was specified

    if ($format eq '' or $id eq '') {
        return $self->formats($id);
    }

    my $app = $self->{$format}->{app};

    if (!$app) {
        my $res = $self->formats($id);
        $res->[0] = 406; # Not Acceptable
        return $res;
    }

    $app->( $env ); # we don't check response type and code by now
}

sub formats {
    my ($self, $id) = @_;

    my $status = 300; # Multiple Choices
    my $type   = 'application/xml; charset: utf-8';
    my @xml    = $id eq '' ?  '<formats>' 
               : "<formats id=\"" . _xmlescape($id) . "\">";

    while (my ($name, $format) = each %$self) {
        my $line = "<format name=\"$name\" type=\"".$format->{type}."\"";
        if ( $format->{docs} ) {
            push @xml, "$line docs=\"" . _xmlescape($format->{docs}) . '" />';
        } else {
            push @xml, "$line />"
        }
    }

    return [ $status, [ 'Content-Type' => $type ],
        [ join "\n", '<?xml version="1.0" encoding="UTF-8"?>', @xml, '</formats>' ] ];
}

sub _xmlescape {
    my $xml = shift;
    if ($xml =~ /[\&\<\>"]/) {
        $xml =~ s/\&/\&amp\;/g;
        $xml =~ s/\</\&lt\;/g;
        $xml =~ s/\>/\&gt\;/g;
        $xml =~ s/"/\&quot\;/g;
    }
    return $xml;
}

1;


__END__
=pod

=head1 NAME

Plack::App::unAPI - Serve via unAPI

=head1 VERSION

version 0.1

=head1 SYNOPSIS

    use Plack::App::unAPI;

    my $app1 = sub { ... };
    my $app2 = sub { ... };
    my $app3 = sub { ... };

    unAPI
        json => [ $app1 => 'application/javascript' ],
        xml  => [ $app2 => 'application/xml' ],
        txt  => [ $app3 => 'text/plain', docs => 'http://example.com' ];

To run this script you can simply call C<plackup yourscript.psgi>.

=head1 DESCRIPTION

This implements an unAPI server as PSGI application. unAPI is a tiny HTTP API
to query discretely identified objects in different formats. See
L<http://unapi.info> for details.

=head1 METHODS

=head2 new ( %formats )

To create an new object you must provide a list of mappings between format
names and PSGI applications to serve requests for the particular format. Each
application is wrapped in an array reference, followed by its MIME type and
optional information fields about the format. So the general form is: 

    format => [ $app => $type, %about ]

The following information fields are supported:

=over

=item docs

An URL of a document that describes the format

=back

=head2 unAPI ( %formats )

The C<unAPI> keyword as constructor alias is exported by default. To prevent
exporting, include this module via C<use Plack::App::unAPI ();>.

=head2 formats ( [$id] )

Returns a PSGI response with status 300 (Multiple Choices) and an XML document
that lists all formats.

=head1 AUTHOR

Jakob Voss

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jakob Voss.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

