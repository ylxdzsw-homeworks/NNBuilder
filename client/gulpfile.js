'use strict'
const gulp        = require('gulp')
const browserSync = require('browser-sync')
const del         = require('del')
const $           = require('gulp-load-plugins')()

let production = true

gulp.task('views', ['styles', 'scripts'],function(){
    return gulp.src(['src/*.jade'])
        .pipe($.plumber())
        .pipe($.jade({
            pretty: !production
        }))
        .on('error', $.util.log)
        .pipe(gulp.dest('build'))
        .pipe(browserSync.reload({stream: true}))
})

gulp.task('styles', function() {
    return gulp.src('src/*.scss')
        .pipe($.plumber())
        .pipe($.sass()
            .on('error', $.util.log))
        .pipe($.autoprefixer({
            browsers: ['last 2 versions']
        }))
        .pipe($.if(production, $.minifyCss()))
        .pipe(gulp.dest('build'))
})

gulp.task('scripts', function() {
    return gulp.src('src/*.coffee')
        .pipe($.plumber())
        .pipe($.coffee())
        .on('error', $.util.log)
        .pipe($.if(production, $.uglify()))
        .pipe(gulp.dest('build'))
})

gulp.task('lib', function() {
    return gulp.src('lib/*')
        .pipe(gulp.dest('build'))
})

gulp.task('browser-sync', function() {
    browserSync({
        proxy: 'localhost:8000',
        serveStatic: [{
            route: ['/', '/static'],
            dir: './build'
        }]
    })
})

gulp.task('watch', ['build'], function() {
    gulp.watch('src/*.scss', ['views'])
    gulp.watch('src/*.jade', ['views'])
    gulp.watch('src/*.coffee', ['views'])

    gulp.start('browser-sync')
})

gulp.task('clean', function(cb) {
    del(['build']).then(paths => cb())
})

gulp.task('build', ['views', 'lib'], function() {
    production && setTimeout(()=>console.info("build complete~"), 0)
})

gulp.task('default', ['clean'], function() {
    production = false
    gulp.start('watch')
})
