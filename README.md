
# brake_stream

This repo reports two minimal reproducible examples for two linked
issues I have encountered w/ shiny development to control video
recording from a USB webcam.

You can run the application by calling one of the following snippets
accordingly to what you would like to see.

``` r
# install.package("shiny")

## "brake the loop" app: a button starting an infinite loop interrupted
## by the click on a stop button.
shiny::runGitHub(
  repo = "break_stream",
  username = "CorradoLanera",
  subdir = "break_loop"
)

## "release the stream" app: click start to start an `{Rvision}` strem,
## and click stop to releas it. reactive or observer for an external
## pointer?! We need immediate side-effect (observer) with a returned 
## value (the pointer: reactive). Release exiting the starting chunk 
## (from the stop click) or releasing from the stop chunk?!
## 
## My current solution: superassign the pointer into the global
## environment from within the observer start chunk, releasing it from
## within the observer stop chunk. VERY ugly!
shiny::runGitHub(
  repo = "break_stream",
  username = "CorradoLanera",
  subdir = "release_stream"
)
```

### UPDATE: solved loop

After looking at <https://blog.fellstat.com/?p=407> (last access:
2022-08-27), I have found a very beautiful solution/workaraund based on
`{future}` and status text temporary file written on disk. I don’t know
if there is a more *shiny* solution; if so, you are more than very
welcome to file a pull request! Similarly, if you find some issue with
that solution, you can file an issue (or a pull request ;-))!

You can find the solution in the branch `loop`, and you can run the
corresponding application executing the following snippet.

``` r
# install.packages("shiny")

## "brake the loop" app: a button starting an infinite loop interrupted
## by the click on a stop button.
shiny::runGitHub(
  repo = "break_stream",
  username = "CorradoLanera",
  ref = "loop",
  subdir = "break_loop"
)
```

## TL;DR

### The point

I need to develop an app that can start and stop recording videos from a
(USB) webcam.

### Issue 1: releasing the stream

Reactives return a value, and they are lazy. That means that if one of
their dependent outputs (or one of their children) is not invalidated
AND needs to be calculated, they *can* be invalidated but **won’t** be
evaluated!

So in the release_stream example, we have two cases:

-   Snapshot: use a reactive for this could be suboptimal, but it works:
    this *can* use reactives because we plot the resulting image. So
    when we invalidate the snapshot, it invalidates the output, which
    will be updated; to do that, shiny must reevaluate (update) the
    snapshot, i.e., the reactive. In this case, everything happens
    inside `reactive()` so we can release the stream using
    `withr::defer()` so that as soon the action is completed (i.e., the
    snapshot is ready), and the reactive value is returned (and cached),
    it kicks in and release the stream.

    > This is ugly (and maybe risky) but works: can we do better?

-   Recording: in the example, we do not perform the recording for
    minimality. The point is to activate a stream and *fill* a video
    from its images until… we stop it! So we need a `start` and a `stop`
    button. The first activates the stream and starts the recording; the
    second stop it (and maybe releases the stream… if not done from the
    start chunk). This time we cannot use reactives because we need to
    be sure the two actions (i.e., start and stop) happened, and they
    happened ASAP! So, we need an observer (eager!). The problem is that
    an observer does not return anything, and we need the pointer to the
    C object used for the stream to release it when the stop button is
    pressed. My ugly solution is to superassign it to the globalenv from
    inside the observer.

    > This is ugly (and maybe risky) but works: can we do better?

### Issue 2: break an infinite loop

To record a video, we need to store inside it a stream of images
indefinitely or up to the moment we push *stop*. But, R is a single
process, and if shiny use it to evaluate the code inside the observer
triggered by the start button… how can we signal to it that we even have
pressed the stop button?

> I do not have found a solution nor a workaround to that.

## Code of Conduct

Please note that the break_stream project is released with a
[Contributor Code of
Conduct](https://contributor-covenant.org/version/2/1/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.
