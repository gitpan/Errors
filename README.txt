Name
---------

Errors::Errors - Module for error/die/exit/abort proceeding.


Synopsis
-------------

use Errors::Errors;
$obj = Errors::Errors->new();

$obj->attach('some'); # Attach sub object for error of type 'some'

$obj->install('onTerm',\&custom);
$obj->install('onError',\&anysub,'some');
$obj->install('onExit',\&leave);
$obj->exit();
sub custom {
my $obj = shift; # 'Errors' object
my $err = shift; # Error number/message (for TERM it has value 'term')
my $name = shift; # 'name' of error (for TERM it has empty value)
# ...blah...blah...
}
sub leave {
my $obj = shift; # 'Errors' object
my $err = shift; # Last error number/message
my $name = shift; # 'name' of error
my $how = shift; # can be: 'exit','die' or 'destroy'
# ...blah...blah...
}
sub anysub {
my $obj = shift; # 'Errors' object
my $err = shift; # Error number/message
my $name = shift; # 'name' of error
if($name =~ m/some/si)
{
$obj->print ("Error in some!");
}
else
{
$obj->print ("Error in ... I don't know :-)!!!");
}
}


Install
---------

As any other 'CPAN' module you just have to do follow simple steps to complete 
installation:

tar -zxvf Errors-1.00.tar.gz
cd Errors-1.00
perl Makefile.PL
make
make test
make install
make clean

After successful installation you can get explore all these pretty stuff :-)


Getting started
---------------------

First question is: Why I have to use Errors module in my Perl program?
In large projects you have to use many libraries, modules and of course you have 
to catch all errors in, also in some cases you need to make some finalize 
procedures at the end of your scripts. To do that you may need to write subs for 
different errors, to write code for interrupts/events/signals but what structure 
you use? None? Huh! You just write code and grubby you program! It's a disgrace. 

This module offer to you and your scripts centralize errors handling and 
proceeding.


How it's works?
----------------------

First you must to create one object for your program:

use Errors::Errors;
$obj = Errors::Errors->new();

This object will contain pointers to your subs that handle occurred errors.
This module can handle follow base errors/events:

exit(onExit), die(onExit), TERM/STOP/PIPE/QUIT(onTerm), ALRM(onTimeout), and 
custom errors(onError).

If you want to do something when your script ends, set your custom sub:

$obj->install('onExit',\&leave);

where \&leave is pointer to your sub 'leave'. When your script ends your sub 

program 'leave' will be executed before the end. That will be happened at the 
end of $obj scope i.e. in DESTROY section of module. Also you can provoke 
execution of 'leave' if you write follow line in program:

$obj->exit($code_error);
or
$obj->die($code_error);

If you want to handle ALRM signal write line like this:

$obj->install('onTimeout',\&custom);
where 'custom' is your custom sub that handle ALRM signal.

To handle TERM/STOP/PIPE/QUIT signals use follow like:

$obj->install('onTerm',\&custom);

where 'custom' is your custom sub that handle listed signals.

If you want to initialize your custom errors write code bellow:

$obj->install('onError',\&anysub);

So when you call method bellow, somewhere in script, you will rise execution of 
'anysub'!

$obj->error($code_error);

Of course all your subs will receive additional parameters so you will be able 
to find reason for errors (and respective error codes). See SYSNOPSIS above.
In single script these methods are strong enough, but if you have a complex 
program with lot of libraries/modules you may want to have a single 'errors' 
object for all your libraries/modules. But how you can handle TERM signal for 
all yours different libraries??? The idea is quite simple, we will still 
continue to use our global (single) object, but we will create "sub objects" for 
all additional libraries/modules! 

To add new sub object do follow:

$obj->attach('some');

This will create sub object called 'some'. To install 'onTerm' signal for this 
sub object (SObject) do follow:

$obj->install('onTerm',\&custom,'some');

Also to catch 'exit' for SObject call:

$obj->install('onExit,',\&leave,'some');

To rise custom error for 'some' SObject, call:

$obj->error($code_error,'some');

To exit…:

$obj->exit($code_error,'some');
… and so on.

Note:
$obj->error($code_error,'some');
will rise error in 'some' sub object
$obj->error($code_error);

will rise error in 'main' object!!! (Think about that like parent object and 
respective children)!

Let imagine that we have a lot of children (SObjects) and one parent object. 
Also let for all these objects we have sub programs that catch exit event. And 
now let our program gone to the end of code, so program must quit and Perl must 
destroy and unload our program!
However Errors module have job to do, it must call all subs that are joined into 
'exit' chain!

See follow block:

foreach $obj call {
| SObject 1 | -> onExit sub
| SObject 2 | -> onExit sub
…
| SObject n | -> onExit sub
| Main object | -> onExit sub
}

All this will be happened with all other events/signals! So you have to check 
reason and decide whether you must do anything into respective sub! See simple 

example:

sub anysub {
my $obj = shift; # 'Errors' object
my $err = shift; # Error number/message
my $name = shift; # 'name' of error
if($name =~ m/some/si)
{
$obj->print ("Error in some!");
}
else
{
$obj->print ("Error in ... I don't know :-)!!!");
}
}

If name is 'some' we can do something, but when the error is somewhere else you 
may want to miss it! You have to decide!

To delete SObject call:

$obj->detach('some');
To uninstall event/signal:
$obj->uninstall('onError','some'); # for some SObject
or
$obj->uninstall('onError'); # for main object

At the end I would like to notice that this module was originally written for 
Web and more correct for WebTools Perl sub system (look at 
http://www.proscriptum.com/)

So to allow Errors object to let know, whether content type is sent use follow 
line:

$obj->content($state); # $state can be '1' - yes and '0' - is not sent yet!

If you want to send default content (HTTP) header use:

$obj->header();

Note: If $obj->content() is '1' then $obj->header() will return immediately 
without printing default header, but if you are not still sent header (or if you 
forgot to tell that to Error object via $obj->content(1) ) then $obj->header() 
will sent default header.

To overwrite default header function use statement bellow:

$obj->install('header',\&your_header_sub);

All this (header and content functions) is needful because if this script is WEB 
based and error occurred you may want to print some text into browser, but if 
you forgot to print content, error will occurred (Internal Error). And vice 
versa: If content is already sent and you print it again then second content 
header will appear in browser :-(

For more information, look at Errors::Errors module.

Author
---------

Julian Lishev,

E-mail: julian@proscriptum.com
URL: http://www.proscriptum.com/