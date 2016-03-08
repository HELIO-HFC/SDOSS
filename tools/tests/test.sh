#! /bin/sh

/usr/local/bin/idl -quiet -rt=/obs/helio/hfc/frc/sdoss/lib/idl/bin/sdoss_hfc_processing.sav \
    -args '/poubelle/helio/hfc/frc/sdoss/hmi.ic_45s.2011.03.08_02:00:00_TAI.continuum.fits' \
    '/poubelle/helio/hfc/frc/sdoss/hmi.m_45s.2011.03.08_02:00:00_TAI.magnetogram.fits' \
    data_dir=/poubelle/helio/hfc/frc/sdoss output_dir=/data/helio/hfc/frc/sdoss \
    feat_min_pix=9 ic_url='http://vso2.tuc.noao.edu/cgi-bin/drms_test/drms_export.cgi?series=hmi__Ic_45s;compress=rice;record=12748960-12748960' \
    m_url='http://vso2.tuc.noao.edu/cgi-bin/drms_test/drms_export.cgi?series=hmi__M_45s;compress=rice;record=12748960-12748960' \
    /CSV /QUICKLOOK /VERBOSE
