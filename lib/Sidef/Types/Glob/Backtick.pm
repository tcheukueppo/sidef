package Sidef::Types::Glob::Backtick {

    use utf8;
    use 5.016;

    use parent qw(
      Sidef::Object::Object
    );

    use overload q{""} => sub {
        'Backtick(' . ${Sidef::Types::String::String->new(${$_[0]})->dump} . ')';
    };

    sub new {
        my (undef, $backtick) = @_;
        bless \(my $o = "$backtick"), __PACKAGE__;
    }

    *call = \&new;

    sub get_value {
        ${$_[0]};
    }

    sub run {
        my ($self) = @_;
        Sidef::Types::String::String->new(scalar `$$self`);
    }

    *execute = \&run;
    *exec    = \&run;

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new("$self");
    }

    *to_s   = \&dump;
    *to_str = \&dump;
};

1
