% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/task.R
\name{Task}
\alias{Task}
\title{R6 Class Representing a Task}
\description{
A \code{Task} stores a function, arguments, output, and metadata.
}
\details{
A \code{Task} object is used as a storage class. It is a container used to hold an
R function and any arguments to be passed to the function. It can also hold
any output returned by the function, anything printed to stdout or stderr
when the function is called, and various other metadata such as the process
id of the worker that executed the function, timestamps, and so on.

The methods for \code{Task} objects fall into two groups, roughly speaking. The
\verb{get_*()} methods are used to return information about the \code{Task}, and the
\verb{register_*()} methods are used to register information related to events
relevant to the \code{Task} status.

The \code{retrieve()} method is special, and returns a tibble containing all
information stored about the task. Objects further up the hierarchy use this
method to return nicely organised output that summarise the results from
many tasks.
}
\section{Methods}{
\subsection{Public methods}{
\itemize{
\item \href{#method-Task-new}{\code{Task$new()}}
\item \href{#method-Task-retrieve}{\code{Task$retrieve()}}
\item \href{#method-Task-get_task_fun}{\code{Task$get_task_fun()}}
\item \href{#method-Task-get_task_args}{\code{Task$get_task_args()}}
\item \href{#method-Task-get_task_state}{\code{Task$get_task_state()}}
\item \href{#method-Task-get_task_id}{\code{Task$get_task_id()}}
\item \href{#method-Task-get_task_runtime}{\code{Task$get_task_runtime()}}
\item \href{#method-Task-register_task_created}{\code{Task$register_task_created()}}
\item \href{#method-Task-register_task_waiting}{\code{Task$register_task_waiting()}}
\item \href{#method-Task-register_task_assigned}{\code{Task$register_task_assigned()}}
\item \href{#method-Task-register_task_running}{\code{Task$register_task_running()}}
\item \href{#method-Task-register_task_done}{\code{Task$register_task_done()}}
\item \href{#method-Task-clone}{\code{Task$clone()}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-Task-new"></a>}}
\if{latex}{\out{\hypertarget{method-Task-new}{}}}
\subsection{Method \code{new()}}{
Create a new task. Conceptually, a \code{Task} is viewed as a
function that will be executed by the \code{Worker} to which it is assigned,
and it is generally expected that any resources the function requires
are passed through the arguments since the execution context will be a
different R session to the one in which the function is defined.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{Task$new(fun, args = list(), id = NULL)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{fun}}{The function to be called when the task executes.}

\item{\code{args}}{A list of arguments to be passed to the function (optional).}

\item{\code{id}}{A string specifying a unique task identifier (optional).}
}
\if{html}{\out{</div>}}
}
\subsection{Returns}{
A new \code{Task} object.
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-Task-retrieve"></a>}}
\if{latex}{\out{\hypertarget{method-Task-retrieve}{}}}
\subsection{Method \code{retrieve()}}{
Retrieve a tidy summary of the task state.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{Task$retrieve()}\if{html}{\out{</div>}}
}

\subsection{Returns}{
A tibble containing a single row, and the following columns:
\itemize{
\item \code{task_id} A character string specifying the task identifier
\item \code{worker_id} An integer specifying the worker process id (pid)
\item \code{state} A character string indicating the task status ("created",
"waiting", "assigned", "running", or "done")
\item \code{result} A list containing the function output, or NULL
\item \code{runtime} Completion time for the task (NA if the task is not done)
\item \code{fun} A list containing the function
\item \code{args} A list containing the arguments
\item \code{created} The time at which the task was created
\item \code{queued} The time at which the task was added to a \code{Queue}
\item \code{assigned} The time at which the task was assigned to a \code{Worker}
\item \code{started} The time at which the \code{Worker} called the function
\item \code{finished} The time at which the \code{Worker} output was returned
\item \code{code} The status code returned by the callr R session (integer)
\item \code{message} The message returned by the callr R session (character)
\item \code{stdout} List containing the contents of stdout during function execution
\item \code{stderr} List containing the contents of stderr during function execution
\item \code{error}  List containing \code{NULL}
}

Note: at present there is one field from the callr rsession::read() method
that isn't captured here, and that's the error field. I'll add that after
I've finished wrapping my head around what that actually does. The \code{error}
column, at present, is included only as a placeholder
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-Task-get_task_fun"></a>}}
\if{latex}{\out{\hypertarget{method-Task-get_task_fun}{}}}
\subsection{Method \code{get_task_fun()}}{
Retrieve the task function.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{Task$get_task_fun()}\if{html}{\out{</div>}}
}

\subsection{Returns}{
A function.
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-Task-get_task_args"></a>}}
\if{latex}{\out{\hypertarget{method-Task-get_task_args}{}}}
\subsection{Method \code{get_task_args()}}{
Retrieve the task arguments
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{Task$get_task_args()}\if{html}{\out{</div>}}
}

\subsection{Returns}{
A list.
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-Task-get_task_state"></a>}}
\if{latex}{\out{\hypertarget{method-Task-get_task_state}{}}}
\subsection{Method \code{get_task_state()}}{
Retrieve the task state.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{Task$get_task_state()}\if{html}{\out{</div>}}
}

\subsection{Returns}{
A string specifying the current state of the task. Possible
values are "created" (task exists), "waiting" (task exists and is
waiting in a queue), "assigned" (task has been assigned to a worker
but has not yet started), "running" (task is running on a worker),
or "done" (task is completed and results have been assigned back
to the task object)
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-Task-get_task_id"></a>}}
\if{latex}{\out{\hypertarget{method-Task-get_task_id}{}}}
\subsection{Method \code{get_task_id()}}{
Retrieve the task id.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{Task$get_task_id()}\if{html}{\out{</div>}}
}

\subsection{Returns}{
A string containing the task identifier.
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-Task-get_task_runtime"></a>}}
\if{latex}{\out{\hypertarget{method-Task-get_task_runtime}{}}}
\subsection{Method \code{get_task_runtime()}}{
Retrieve the task runtime.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{Task$get_task_runtime()}\if{html}{\out{</div>}}
}

\subsection{Returns}{
If the task has completed, a difftime value. If the task has
yet to complete, a \code{NA} value is returned
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-Task-register_task_created"></a>}}
\if{latex}{\out{\hypertarget{method-Task-register_task_created}{}}}
\subsection{Method \code{register_task_created()}}{
Register the task creation by updating internal storage.
When this method is called, the state of the \code{Task} is set to "created"
and a timestamp is recorded, registering the creation time for the task.
This method is intended to be called by \code{Worker} objects. Users should
not need to call it.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{Task$register_task_created()}\if{html}{\out{</div>}}
}

\subsection{Returns}{
Returns \code{NULL} invisibly.
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-Task-register_task_waiting"></a>}}
\if{latex}{\out{\hypertarget{method-Task-register_task_waiting}{}}}
\subsection{Method \code{register_task_waiting()}}{
Register the addition of the task to a queue by updating
internal storage. When this method is called, the state of the \code{Task}
is set to "waiting" and a timestamp is recorded, registering the time
at which the task was added to a queue. This method is intended to be
called by \code{Worker} objects. Users should not need to call it.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{Task$register_task_waiting()}\if{html}{\out{</div>}}
}

\subsection{Returns}{
Returns \code{NULL} invisibly.
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-Task-register_task_assigned"></a>}}
\if{latex}{\out{\hypertarget{method-Task-register_task_assigned}{}}}
\subsection{Method \code{register_task_assigned()}}{
Register the assignment of a task to a worker by updating
internal storage. When this method is called, the state of the \code{Task}
is set to "assigned" and a timestamp is recorded, registering the time
at which the task was assigned to a \code{Worker}. In addition, the
\code{worker_id} of the worker object (which is also it's pid) is registered
with the task. This method is intended to be called by \code{Worker} objects.
Users should not need to call it.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{Task$register_task_assigned(worker_id)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{worker_id}}{Identifier for the worker to which the task is assigned.}
}
\if{html}{\out{</div>}}
}
\subsection{Returns}{
Returns \code{NULL} invisibly.
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-Task-register_task_running"></a>}}
\if{latex}{\out{\hypertarget{method-Task-register_task_running}{}}}
\subsection{Method \code{register_task_running()}}{
Register the commencement of a task to a worker by updating
internal storage. When this method is called, the state of the \code{Task} is
set to "running" and a timestamp is recorded, registering the time at
which the \code{Worker} called the task function. In addition, the \code{worker_id}
is recorded, albeit somewhat unnecessarily since this information is
likely already stored when \code{register_task_assigned()} is called. This
method is intended to be called by \code{Worker} objects. Users should not
need to call it.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{Task$register_task_running(worker_id)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{worker_id}}{Identifier for the worker on which the task is starting.}
}
\if{html}{\out{</div>}}
}
\subsection{Returns}{
Returns \code{NULL} invisibly.
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-Task-register_task_done"></a>}}
\if{latex}{\out{\hypertarget{method-Task-register_task_done}{}}}
\subsection{Method \code{register_task_done()}}{
Register the finishing of a task to a worker by updating
internal storage. When this method is called, the state of the \code{Task} is
set to "done" and a timestamp is recorded, registering the time at which
the \code{Worker} returned results to the \code{Task}. The \code{results} object is
read from the R session, and is stored locally by the \code{Task} at this time.
This method is intended to be called by \code{Worker} objects. Users should
not need to call it.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{Task$register_task_done(results)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{results}}{Results read from the R session.}
}
\if{html}{\out{</div>}}
}
\subsection{Returns}{
Returns \code{NULL} invisibly.
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-Task-clone"></a>}}
\if{latex}{\out{\hypertarget{method-Task-clone}{}}}
\subsection{Method \code{clone()}}{
The objects of this class are cloneable with this method.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{Task$clone(deep = FALSE)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{deep}}{Whether to make a deep clone.}
}
\if{html}{\out{</div>}}
}
}
}
