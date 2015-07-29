package Sidef::Types::Array::RangeString {

    use 5.014;
    use parent qw(
      Sidef::Object::Object
      );

    sub new {
        my (undef, %opt) = @_;
        bless \%opt, __PACKAGE__;
    }

    sub min {
        my ($self) = @_;
        Sidef::Types::String::String->new($self->{direction} eq 'up' ? $self->{from} : $self->{to});
    }

    sub max {
        my ($self) = @_;
        Sidef::Types::String::String->new($self->{direction} eq 'up' ? $self->{to} : $self->{from});
    }

    sub bounds {
        my ($self) = @_;
        Sidef::Types::Array::List->new($self->min, $self->max);
    }

    sub contains {
        my ($self, $num) = @_;

        my $value = $num->get_value;
        my ($min, $max) = map { $_->get_value } ($self->min, $self->max);

        Sidef::Types::Bool::Bool->new($value ge $min and $value le $max);
    }

    *includes = \&contains;

    sub each {
        my ($self, $code) = @_;

        my $from = $self->{from};
        my $to   = $self->{to};

        if ($self->{direction} eq 'up') {
            if (length($from) == 1 and length($to) == 1) {
                foreach my $i (ord($from) .. ord($to)) {
                    if (defined(my $res = $code->_run_code(Sidef::Types::String::String->new(chr($i))))) {
                        return $res;
                    }
                }
            }
            else {
                foreach my $str ($from .. $to) {    # this is lazy
                    if (defined(my $res = $code->_run_code(Sidef::Types::String::String->new($str)))) {
                        return $res;
                    }
                }
            }
        }
        else {
            if (length($from) == 1 and length($to) == 1) {
                my $f = ord($from);
                my $t = ord($to);
                for (; $f >= $t ; $f--) {
                    if (defined(my $res = $code->_run_code(Sidef::Types::String::String->new(chr($f))))) {
                        return $res;
                    }
                }
            }
            else {
                foreach my $str (reverse($from .. $to)) {    # this is not lazy
                    if (defined(my $res = $code->_run_code(Sidef::Types::String::String->new($str)))) {
                        return $res;
                    }
                }
            }
        }

    }

    our $AUTOLOAD;
    sub DESTROY { }

    sub to_array {
        my ($self) = @_;
        local $AUTOLOAD;
        $self->AUTOLOAD();
    }

    *to_a = \&to_array;

    sub AUTOLOAD {
        my ($self, @args) = @_;

        my ($name) = (defined($AUTOLOAD) ? ($AUTOLOAD =~ /^.*[^:]::(.*)$/) : '');

        my $array;
        my $method = $self->{direction} eq 'up' ? 'array_to' : 'array_downto';

        my $from = $self->{from};
        my $to   = $self->{to};
        $array = Sidef::Types::String::String->new($from)->$method(Sidef::Types::String::String->new($to));

        $name eq '' ? $array : $array->$name(@args);
    }

}

1;
