## Bootstrapping OpenJDK 8

```sh
sudo emerge -a1v =dev-java/icedtea-3.7.0
sudo emerge -av dev-java/openjdk:8
```

Note: you need to do it in two steps as currently ant-core:bootstrap is not co-installable
with ant-core:0 from the Gentoo tree.

## Bootstrapping OpenJDK 11
```sh
sudo emerge -a1v dev-java/openjdk:11
```
At this point you can remove this overlay and install OpenJDK from main tree:
```sh
sudo emerge -a dev-java/openjdk:11
```

## Bootstrapping story

We first compile fastjar and jikes java compiler both of which are written in C++.
This is enough to compile an old version of GNU Classpath 0.93. Then we compile an old
version of JamVM 1.5.1. This serves as our initial Java Runtime Environment.

We use this to compile ant 1.8.1 which then allows us to build ecj-3.2. This allows us
to compile GNU Classpath 0.99 which comes with more java tools (e.g. javah). Then we
compile JamVM 2.0.0. This serves as our second Java environment.

Finally, we compile git snapshot of GNU Classpath which has a much better support for Java 1.6.
Then we compile a slightly patched ecj-4.2. Together with JamVM 2.0.0 this will serve as
Java environment that can bootstrap Icedtea 2 (Java 7). Unfortunately, I was only able to build
Java 7 with JamVM as VM (which is slower), Hotspot build failed. JamVM with OpenJDK 7 classes
can build Icedtea 3 with Hotspot VM.
