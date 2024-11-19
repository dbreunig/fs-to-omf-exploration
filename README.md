This is a quick and dirty exploration comparing Overture Maps Foundation data with FourSquare's open POI data. The data here is a subset of both, limited to Alameda, California.

`staging.db` is a DuckDB database that contains 3 tables:

- `omf`: Overture places
- `fs`: FourSquare points of interest
- `matches`: A many-to-many join table of candidate linkages with component scores and metadata.

The SQL used to generate the `matches` table is provided in `conflation.sql`. But first, you have to download the Overture and Foursquare data, which I am not providing here. Check out each respective site for details.