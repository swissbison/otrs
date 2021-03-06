# --
# Copyright (C) 2001-2016 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

## no critic (Modules::RequireExplicitPackage)
use strict;
use warnings;
use utf8;

use vars (qw($Self));

my $Home = $Kernel::OM->Get('Kernel::Config')->Get('Home');

my $Daemon = $Home . '/bin/otrs.Daemon.pl';

# get current daemon status
my $PreviousDaemonStatus = `$Daemon status`;

# stop daemon if it was already running before this test
if ( $PreviousDaemonStatus =~ m{Daemon running}i ) {
    `$Daemon stop`;

    my $SleepTime = 2;

    # wait to get daemon fully stopped before test continues
    print "A running Daemon was detected and need to be stopped...\n";
    print 'Sleeping ' . $SleepTime . "s\n";
    sleep $SleepTime;
}

my $Helper            = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $SchedulerDBObject = $Kernel::OM->Get('Kernel::System::Daemon::SchedulerDB');

$Self->Is(
    ref $SchedulerDBObject,
    'Kernel::System::Daemon::SchedulerDB',
    "Kernel::System::Daemon::SchedulerDB->new()",
);

my $TaskWorkerObject = $Kernel::OM->Get('Kernel::System::Daemon::DaemonModules::SchedulerTaskWorker');

# wait until task is executed
ACTIVESLEEP:
for my $Sec ( 1 .. 120 ) {

    # run the worker
    $TaskWorkerObject->Run();

    my @List = $SchedulerDBObject->TaskList();

    last ACTIVESLEEP if !scalar @List;

    sleep 1;

    print "Waiting $Sec secs for scheduler tasks to be executed\n";
}

# get cache object
my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

# delete any cache
$CacheObject->CleanUp(
    Type => 'SchedulerDBRecurrentTaskExecute'
);

# freeze time
$Helper->FixedTimeSet();

my $TimeObject = $Kernel::OM->Get('Kernel::System::Time');

my $SystemTime = $TimeObject->SystemTime();

my ( $Sec, $Min, $Hour, $Day, $Month, $Year, $WeekDay ) = $TimeObject->SystemTime2Date(
    SystemTime => $SystemTime,
);

my $SecsDiff = 60 - $Sec;

# fix time to have 0 seconds in the current minute
$Helper->FixedTimeAddSeconds($SecsDiff);

$SystemTime = $TimeObject->SystemTime();
my $DateTime  = $Kernel::OM->Create('Kernel::System::DateTime');
my $TimeStamp = $DateTime->ToString();

$DateTime->Add( Seconds => 60 );
my $TimeStamp2 = $DateTime->ToString();

# RecurrentTaskExecute() tests (RecurrentTaskGet() and RecurrentTaskList() are implicit)
my @Tests = (
    {
        Name    => 'Empty Config',
        Config  => {},
        Success => 0,
    },
    {
        Name   => 'Missing NodeID',
        Config => {
            PID                    => 456,
            TaskName               => 'UnitTest1',
            TaskType               => 'UnitTest',
            PreviousEventTimestamp => $TimeStamp,
            Data                   => {},
        },
        Success => 0,
    },
    {
        Name   => 'Missing PID',
        Config => {
            NodeID                 => 1,
            TaskName               => 'UnitTest1',
            TaskType               => 'UnitTest',
            PreviousEventTimestamp => $TimeStamp,
            Data                   => {},
        },
        Success => 0,
    },
    {
        Name   => 'Missing TaskName',
        Config => {
            NodeID                 => 1,
            PID                    => 456,
            TaskType               => 'UnitTest',
            PreviousEventTimestamp => $TimeStamp,
            Data                   => {},
        },
        Success => 0,
    },
    {
        Name   => 'Missing TaskType',
        Config => {
            NodeID                 => 1,
            PID                    => 456,
            TaskName               => 'UnitTest1',
            PreviousEventTimestamp => $TimeStamp,
            Data                   => {},
        },
        Success => 0,
    },
    {
        Name   => 'Missing PreviousEventTimestamp',
        Config => {
            NodeID   => 1,
            PID      => 456,
            TaskName => 'UnitTest1',
            TaskType => 'UnitTest',
            Data     => {},
        },
        Success => 0,
    },
    {
        Name   => 'Missing Data',
        Config => {
            NodeID                 => 1,
            PID                    => 456,
            TaskName               => 'UnitTest1',
            TaskType               => 'UnitTest',
            PreviousEventTimestamp => $TimeStamp,
        },
        Success => 0,
    },
    {
        Name   => 'Correct Initial',
        Config => {
            NodeID                 => 1,
            PID                    => 456,
            TaskName               => 'UnitTest1',
            TaskType               => 'UnitTest',
            PreviousEventTimestamp => $TimeStamp,
            Data                   => {},
        },
        ExpectedTask => {
            Name              => 'UnitTest1',
            Type              => 'UnitTest',
            LastExecutionTime => $TimeStamp,
            LockKey           => 0,
            LockTime          => '',
            CreateTime        => $SystemTime,
            ChangeTime        => $SystemTime,
        },
        Success          => 1,
        RecurrentTaskAdd => 1,
        WorkerTaskAdd    => 0,
    },
    {
        Name   => 'Correct (after 30 secs)',
        Config => {
            NodeID                 => 1,
            PID                    => 456,
            TaskName               => 'UnitTest1',
            TaskType               => 'UnitTest',
            PreviousEventTimestamp => $TimeStamp,
            Data                   => {},
        },
        ExpectedTask => {
            Name              => 'UnitTest1',
            Type              => 'UnitTest',
            LastExecutionTime => $TimeStamp,
            LockKey           => 0,
            LockTime          => '',
            CreateTime        => $SystemTime,
            ChangeTime        => $SystemTime,
        },
        Success          => 1,
        AddSecondsBefore => 30,
        RecurrentTaskAdd => 1,
        WorkerTaskAdd    => 0,
    },
    {
        Name   => 'Correct (after 60 secs)',
        Config => {
            NodeID                 => 1,
            PID                    => 456,
            TaskName               => 'UnitTest1',
            TaskType               => 'UnitTest',
            PreviousEventTimestamp => $TimeStamp2,
            Data                   => {},
        },
        ExpectedTask => {
            Name              => 'UnitTest1',
            Type              => 'UnitTest',
            LastExecutionTime => $TimeStamp2,
            LockKey           => 0,
            LockTime          => '',
            CreateTime        => $SystemTime,
            ChangeTime        => $SystemTime + 60,
        },
        Success          => 1,
        AddSecondsBefore => 30,
        RecurrentTaskAdd => 1,
        WorkerTaskAdd    => 1,
    },
    {
        Name   => 'Correct (after 90 secs)',
        Config => {
            NodeID                 => 1,
            PID                    => 456,
            TaskName               => 'UnitTest1',
            TaskType               => 'UnitTest',
            PreviousEventTimestamp => $TimeStamp2,
            Data                   => {},
        },
        ExpectedTask => {
            Name              => 'UnitTest1',
            Type              => 'UnitTest',
            LastExecutionTime => $TimeStamp2,
            LockKey           => 0,
            LockTime          => '',
            CreateTime        => $SystemTime,
            ChangeTime        => $SystemTime + 60,
        },
        Success          => 1,
        AddSecondsBefore => 30,
        RecurrentTaskAdd => 1,
        WorkerTaskAdd    => 0,
    },
    {
        Name   => 'Correct (after 90 secs w/o cache)',
        Config => {
            NodeID                 => 1,
            PID                    => 456,
            TaskName               => 'UnitTest1',
            TaskType               => 'UnitTest',
            PreviousEventTimestamp => $TimeStamp2,
            Data                   => {},
        },
        ExpectedTask => {
            Name              => 'UnitTest1',
            Type              => 'UnitTest',
            LastExecutionTime => $TimeStamp2,
            LockKey           => 0,
            LockTime          => '',
            CreateTime        => $SystemTime,
            ChangeTime        => $SystemTime + 60,
        },
        Success          => 1,
        AddSecondsBefore => 30,
        RecurrentTaskAdd => 1,
        WorkerTaskAdd    => 0,
        NoCache          => 1,
    },
);

TEST:
for my $Test (@Tests) {

    if ( $Test->{AddSecondsBefore} ) {
        my $StartSystemTime = $TimeObject->SystemTime();
        $Helper->FixedTimeAddSeconds( $Test->{AddSecondsBefore} );
        my $EndSystemTime = $TimeObject->SystemTime();
        print("  Added $Test->{AddSecondsBefore} seconds to time from $StartSystemTime to $EndSystemTime\n");
    }

    # cleanup Task Manager Cache
    my $Cache;
    if ( $Test->{NoCache} ) {
        $Cache = $CacheObject->Get(
            Type           => 'SchedulerDBRecurrentTaskExecute',
            Key            => $Test->{Config}->{TaskName} . '::UnitTest',
            CacheInMemory  => 0,
            CacheInBackend => 1,
        );
        $CacheObject->CleanUp(
            Type => 'SchedulerDBRecurrentTaskExecute',
        );
        print "  Cache cleared before RecurrentTaskExecute()...\n"
    }

    my $Success = $SchedulerDBObject->RecurrentTaskExecute( %{ $Test->{Config} } );

    # return the cache as it was
    if ( $Test->{NoCache} ) {
        $CacheObject->Set(
            Type           => 'SchedulerDBRecurrentTaskExecute',
            Key            => $Test->{Config}->{TaskName} . '::UnitTest',
            Value          => $Cache,
            TTL            => 60 * 5,
            CacheInMemory  => 0,
            CacheInBackend => 1,
        );
        print "  Cache restored after task manager execution...\n";
    }

    if ( !$Test->{Success} ) {
        $Self->False(
            $Success,
            "$Test->{Name} RecurrentTaskExecute() - result with false",
        );

        next TEST;
    }

    $Self->True(
        $Success,
        "$Test->{Name} RecurrentTaskExecute() - result with true",
    );

    # recurrent task check
    my @List = $SchedulerDBObject->RecurrentTaskList(
        Type => 'UnitTest',
    );

    my @FilteredList = grep { $_->{Name} eq $Test->{Config}->{TaskName} } @List;

    if ( $Test->{RecurrentTaskAdd} ) {

        $Self->Is(
            scalar @FilteredList,
            1,
            "$Test->{Name} RecurrentTaskExecute() - creates one recurrent task",
        );

        my %Task = $SchedulerDBObject->RecurrentTaskGet(
            TaskID => $FilteredList[0]->{TaskID},
        );

        my %ExpectedTask;

        # prepare a task expected result
        for my $Attribute ( sort keys %{ $Test->{ExpectedTask} } ) {

            # set time stamps from system times
            if ( $Attribute eq 'CreateTime' || $Attribute eq 'ChangeTime' ) {
                $ExpectedTask{$Attribute} = $TimeObject->SystemTime2TimeStamp(
                    SystemTime => $Test->{ExpectedTask}->{$Attribute},
                );
            }
            else {
                $ExpectedTask{$Attribute} = $Test->{ExpectedTask}->{$Attribute}
            }
        }

        # add task ID
        $ExpectedTask{TaskID} = $FilteredList[0]->{TaskID};

        $Self->IsDeeply(
            \%Task,
            \%ExpectedTask,
            "$Test->{Name} RecurrentTaskGet() - results",
        );
    }
    else {
        $Self->Is(
            scalar @FilteredList,
            0,
            "$Test->{Name} RecurrentTaskExecute() - creates no recurrent tasks",
        );
    }

    # worker task check
    @List = $SchedulerDBObject->TaskList(
        Type => 'UnitTest',
    );

    @FilteredList = grep { $_->{Name} eq $Test->{Config}->{TaskName} } @List;

    if ( $Test->{WorkerTaskAdd} ) {

        $Self->Is(
            scalar @FilteredList,
            1,
            "$Test->{Name} RecurrentTaskExecute() - creates one worker task",
        );

        my $TaskID = $FilteredList[0]->{TaskID};

        my $Success = $SchedulerDBObject->TaskDelete(
            TaskID => $TaskID,
        );
        $Self->True(
            $Success,
            "TaskDelete() - for $TaskID with true",
        );
    }
    else {
        $Self->Is(
            scalar @FilteredList,
            0,
            "$Test->{Name} RecurrentTaskExecute() - creates no worker tasks",
        );
    }

}

my $TaskCleanup = sub {
    my %Param = @_;

    my $Message = $Param{Message} || '';

    # cleanup (RecurrentTaksDelete() positive results)
    my @List = $SchedulerDBObject->RecurrentTaskList(
        Type => 'UnitTest',
    );

    TASK:
    for my $Task (@List) {
        next TASK if $Task->{Type} ne 'UnitTest';

        my $TaskID = $Task->{TaskID};

        my $Success = $SchedulerDBObject->RecurrentTaskDelete(
            TaskID => $TaskID,
        );
        $Self->True(
            $Success,
            "$Message RecurrentTaskDelete() - for $TaskID with true",
        );
    }

    # remove also worker tasks
    @List = $SchedulerDBObject->TaskList(
        Type => 'UnitTest',
    );

    TASK:
    for my $Task (@List) {
        next TASK if $Task->{Type} ne 'UnitTest';

        my $TaskID = $Task->{TaskID};

        my $Success = $SchedulerDBObject->TaskDelete(
            TaskID => $TaskID,
        );
        $Self->True(
            $Success,
            "$Message TaskDelete() - for $TaskID with true",
        );
    }
};

$TaskCleanup->(
    Message => 'Cleanup',
);

# MaximumParallelTask feature test
my %TaskTemplate = (
    NodeID   => 1,
    PID      => 456,
    TaskName => 'UniqueTaskName',
    TaskType => 'UnitTest',
    Data     => {},
);
@Tests = (
    {
        Name                     => "1 task",
        MaximumParallelInstances => 1,
    },
    {
        Name                     => "5 tasks",
        MaximumParallelInstances => 10,
    },
    {
        Name                     => "9 tasks",
        MaximumParallelInstances => 9,
    },
    {
        Name                     => "10 tasks",
        MaximumParallelInstances => 10,
    },
    {
        Name                     => "Unlimited tasks",
        MaximumParallelInstances => 10,
    },
);

for my $Test (@Tests) {

    for my $Counter ( 0 .. 10 ) {

        my $DateTime = $Kernel::OM->Create('Kernel::System::DateTime');
        $DateTime->Subtract( Seconds => 60 );

        my $Success = $SchedulerDBObject->RecurrentTaskExecute(
            %TaskTemplate,
            PreviousEventTimestamp   => $DateTime->ToString(),
            MaximumParallelInstances => $Test->{MaximumParallelInstances},
        );
        $Self->True(
            $Success,
            "$Test->{Name} RecurrentTaskExecute() - result with true",
        );

        $Helper->FixedTimeAddSeconds(60);
    }

    my @List = $SchedulerDBObject->TaskList(
        Type => 'UnitTest',
    );

    my @FilteredList = grep { $_->{Name} eq $TaskTemplate{TaskName} } @List;

    my $ExpectedTaskNumber = $Test->{MaximumParallelInstances} || 10;

    if ( $ExpectedTaskNumber > 10 ) {
        $ExpectedTaskNumber = 10;
    }

    $Self->Is(
        scalar @FilteredList,
        $ExpectedTaskNumber,
        "$Test->{Name} TaskList() - Number of worker tasks",
    );

    $TaskCleanup->(
        Message => "$Test->{Name}"
    );
}

# RecurrentTaskUnlockExpired() tests
# add a new recurrent task (manually as worker is not needed)
my $TaskName = 'UnitTest';
my $TaskType = 'UnitTest';
my $LockKey  = 12345678;

$Kernel::OM->Get('Kernel::System::DB')->Do(
    SQL => "
        INSERT INTO scheduler_recurrent_task
            (name, task_type, last_execution_time, lock_key, lock_time, create_time, change_time)
        VALUES
            (?, ?, current_timestamp, ?, current_timestamp, current_timestamp, current_timestamp)",
    Bind => [
        \$TaskName,
        \$TaskType,
        \$LockKey,
    ],
);

my @List = $SchedulerDBObject->RecurrentTaskList(
    Type => 'UnitTest',
);

my %Task = $SchedulerDBObject->RecurrentTaskGet(
    TaskID => $List[0]->{TaskID},
);

$Self->Is(
    $Task{LockKey},
    $LockKey,
    "LockKey"
);

@Tests = (
    {
        Name    => 'After 0 secs',
        LockKey => $LockKey,
    },
    {
        Name       => 'After 30 secs',
        AddSeconds => 30,
        LockKey    => $LockKey,
    },
    {
        Name       => 'After 59 secs',
        AddSeconds => 29,
        LockKey    => $LockKey,
    },
    {
        Name       => 'After 60 secs',
        AddSeconds => 1,
        LockKey    => 0,
    },
    {
        Name       => 'After 61 secs',
        AddSeconds => 1,
        LockKey    => 0,
    },
);

for my $Test (@Tests) {

    if ( $Test->{AddSeconds} ) {
        $Helper->FixedTimeAddSeconds( $Test->{AddSeconds} );
    }

    $SchedulerDBObject->RecurrentTaskUnlockExpired(
        Type => 'UnitTest',
    );

    my @List = $SchedulerDBObject->RecurrentTaskList(
        Type => 'UnitTest',
    );

    my %Task = $SchedulerDBObject->RecurrentTaskGet(
        TaskID => $List[0]->{TaskID},
    );

    $Self->Is(
        $Task{LockKey},
        $Test->{LockKey},
        "LockKey"
    );

}

# System cleanup.
my $Success = $SchedulerDBObject->RecurrentTaskDelete(
    TaskID => $List[0]->{TaskID},
);

$Self->True(
    $Success,
    "Deleted Task $List[0]->{TaskID}",
);

# start daemon if it was already running before this test
if ( $PreviousDaemonStatus =~ m{Daemon running}i ) {
    system("$Daemon start");
}

1;
