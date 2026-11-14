#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Score HighScore

cat << EOF

    draw_text(
        format!("Score: {}", ${!score}).as_str(),
        10.0,
        35.0,
        25.0,
        WHITE,
    );
    let highscore_text = format!("High score: {}", ${!high_score});
    let text_dimensions = measure_text(highscore_text.as_str(), None, 25, 1.0);
    draw_text(
        highscore_text.as_str(),
        screen_width() - text_dimensions.width - 10.0,
        35.0,
        25.0,
        WHITE,
    );

EOF
