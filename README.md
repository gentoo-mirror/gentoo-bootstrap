## Bootstrapping OpenJDK 8

```
sudo emerge -a1v =dev-java/gnu-classpath-0.93
sudo emerge -a1v =dev-java/jamvm-1.5.1
sudo emerge -a1v =dev-java/gnu-classpath-0.99-r2
sudo emerge -a1v =dev-java/jamvm-2.0.0-r99
sudo emerge -a1v =dev-java/eclipse-ecj-4.2.1
sudo emerge -a1v =dev-java/jamvm-2.0.0-r100
sudo emerge -a1v dev-java/icedtea:7
sudo emerge -a dev-java/openjdk:8 # This will be installed form the main Gentoo portage tree
```

## Bootstrapping OpenJDK 11
```
sudo emerge -a1v dev-java/openjdk:9
sudo emerge -a1v dev-java/openjdk:10
sudo emerge -a1v dev-java/openjdk:11
```
At this point you can remove this overlay and install OpenJDK from main tree:
```
sudo emerge -a dev-java/openjdk:11
```
