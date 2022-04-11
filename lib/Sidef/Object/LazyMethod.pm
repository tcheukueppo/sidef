package Sidef::Object::LazyMethod {

    use utf8;
    use 5.016;

    use parent qw(
      Sidef::Object::Object
    );

    our $AUTOLOAD;

    sub new {
        my (undef, @calls) = @_;
        bless {calls => \@calls}, __PACKAGE__;
    }

    sub method {
        my ($self, $method, @args) = @_;
        __PACKAGE__->new(
                         @{$self->{calls}},
                         {
                          method => $method,
                          args   => \@args,
                         }
                        );
    }

    sub DESTROY { }

    sub AUTOLOAD {
        my ($self, @args) = @_;

        my ($want) = ($AUTOLOAD =~ /^.*[^:]::(.*)$/);

        my $obj = $self->{calls}[0]{obj};

        foreach my $i (0 .. $#{$self->{calls}} - 1) {
            my $call   = $self->{calls}[$i];
            my $method = $call->{method};

            if (ref($obj)) {
                $obj = $obj->$method(@{$call->{args}});
            }
            else {
                my $code = UNIVERSAL::can($obj, $method);
                $obj = $code->(@{$call->{args}});
            }
        }

        my $call   = $self->{calls}[-1];
        my $method = $call->{method};

        if ($want eq 'call' or $want eq 'run') {

            if (ref($obj)) {
                return $obj->$method(@{$call->{args}}, @args);
            }

            my $code = UNIVERSAL::can($obj, $method);
            @_ = (@{$call->{args}}, @args);
            $code // die "[ERROR] Can't call an undefined method for <<$obj>>!";
            goto $code;
        }

        if (ref($obj)) {
            return $obj->$method(@{$call->{args}})->$want(@args);
        }

        my $code = UNIVERSAL::can($obj, $method);
        $code->(@{$call->{args}})->$want(@args);
    }

};

1
