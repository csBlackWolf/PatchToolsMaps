import copy
import importlib.util
import unittest
from pathlib import Path

spec=importlib.util.spec_from_file_location('generate_catalog',Path(__file__).resolve().parents[1]/'tools/generate_catalog.py')
module=importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class CatalogTests(unittest.TestCase):
    def setUp(self):
        self.tables={
            'UiMapArt':[{'ID':1,'UiMapArtStyleID':2}],
            'UiMapArtStyleLayer':[{'UiMapArtStyleID':2,'LayerIndex':0,'LayerWidth':1002,'LayerHeight':668,'TileWidth':256,'TileHeight':256}],
            'UiMapXMapArt':[{'UiMapArtID':1}],
            'WorldMapOverlay':[{'ID':3,'UiMapArtID':1,'TextureWidth':300,'TextureHeight':300,'OffsetX':4,'OffsetY':6,'Flags':4,'PlayerConditionID':0}],
            'WorldMapOverlayTile':[{'WorldMapOverlayID':3,'LayerIndex':0,'RowIndex':r,'ColIndex':c,'FileDataID':100+2*r+c}
                                   for r,c in ((1,1),(0,1),(1,0),(0,0))],
        }

    def test_explicit_tile_positions_and_zero_based_layer(self):
        catalog,_=module.generate(self.tables)
        overlay=catalog[1]['1:1002:668:256:256'][0]
        self.assertEqual(overlay['fileDataIDs'],[100,101,102,103])
        self.assertEqual(overlay['offsetX'],4)

    def test_missing_and_duplicate_tiles_rejected(self):
        self.tables['WorldMapOverlayTile'].pop()
        with self.assertRaises(ValueError): module.generate(self.tables)
        self.setUp()
        self.tables['WorldMapOverlayTile'].append(copy.deepcopy(self.tables['WorldMapOverlayTile'][0]))
        with self.assertRaises(ValueError): module.generate(self.tables)

    def test_other_flags_and_player_conditions_excluded(self):
        for field,value in (('Flags',1),('Flags',8),('PlayerConditionID',10)):
            self.setUp()
            self.tables['WorldMapOverlay'][0][field]=value
            catalog,skipped=module.generate(self.tables)
            self.assertEqual(catalog,{})
            self.assertEqual(skipped,{'special_or_conditional':1})

    def test_empty_geometry_and_unavailable_images_reported(self):
        self.tables['WorldMapOverlayTile']=[]
        catalog,skipped=module.generate(self.tables)
        self.assertEqual(skipped,{'missing_tiles':1})
        self.tables['WorldMapOverlay'][0]['TextureWidth']=0
        catalog,skipped=module.generate(self.tables)
        self.assertEqual(skipped,{'no_renderable_geometry':1})


if __name__=='__main__': unittest.main()
