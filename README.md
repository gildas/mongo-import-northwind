# mongo-import-northwind
Simple Docker to import the Northwind Mongo Database into a Mongo container

## Usage

You can get help here:  
```console
docker run --rm -t gildas/mongo-import-northwind --help
```

Without a docker network, we can `link` the proper container:  
```console
docker run --rm -t --link db gildas/mongo-import-northwind --host db --verbose
```

With a docker network, we would run this:
```console
docker run --rm -t --net mynet gildas/mongo-import-northwind --host db --verbose
```

(Provided that _db_ is the container hosting the Mongo Database)

