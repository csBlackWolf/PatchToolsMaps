local _, Maps = ...
-- Explicit aliases only, verified against local client tables and texture headers.
-- See CATALOG-MANIFEST-FOREVER-70862.json for the comparison with build 70790.
-- Builds 70888 and 70938 were checked separately; see their manifests.
Maps.catalogBuildAliases = {[70862]=70790,[70888]=70790,[70938]=70790}

-- Newest bundled data first. Unknown client builds keep using their own product's
-- catalog; GetCatalog still requires the same art ID, layer and tile geometry.
Maps.catalogProductBuilds = {forever={70790,70532},era={70576,70003}}
