package Sidef::Types::Glob::Pipe {

    use 5.014;
    use parent qw(
      Sidef::Object::Object
      );

    use overload q{""} => sub {
        'Pipe(' . join(', ', map { ${Sidef::Types::String::String->new("$_")->dump} } @{$_[0]}) . ')';
    };

    sub new {
        my (undef, @command) = @_;
        bless \@command, __PACKAGE__;
    }

    *call = \&new;

    sub get_value {
        join(' ', @{$_[0]});
    }

    sub command {
        my ($self) = @_;
        @{$self} > 1 ? (@{$self}) : $self->[0];
    }

    sub open {
        ref($_[0]) || shift(@_);
        my ($self, $mode, $var_ref) = @_;

        if (ref $mode) {
            $mode = "$mode";
        }

        my $pid = open(my $pipe_h, $mode, @{$self});
        my $pipe_obj = Sidef::Types::Glob::FileHandle->new(fh => $pipe_h, self => $self);

        if (defined($var_ref)) {
            ${$var_ref} = $pipe_obj;

            return defined($pid)
              ? Sidef::Types::Number::Number->new($pid)
              : ();
        }

        defined($pid) ? $pipe_obj : ();
    }

    sub open_r {
        ref($_[0]) || shift(@_);
        my ($self, $var_ref) = @_;
        $self->open('-|:utf8', $var_ref);
    }

    *open_read = \&open_r;

    sub open_w {
        ref($_[0]) || shift(@_);
        my ($self, $var_ref) = @_;
        $self->open('|-:utf8', $var_ref);
    }

    *open_write = \&open_w;

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new("$self");
    }
}

1;
