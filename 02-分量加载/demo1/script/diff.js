// import DiffMatchPatch from 'diff-match-patch';
 
// const dmp = new DiffMatchPatch();
// const diff = dmp.diff_main('dogs bark', 'cats bark');

var DiffMatchPatch=require('diff-match-patch');
var fs = require('fs'),
path = require('path');


var data1 = fs.readFileSync(path.resolve(__dirname, '../dist/common.bundle'), 'utf8');
var data2 = fs.readFileSync(path.resolve(__dirname, '../dist/index.bundle'), 'utf8');

var ms_start = (new Date).getTime();

var dmp = new DiffMatchPatch();
var diff = dmp.diff_main(data1, data2,true);
if (diff.length > 2) {
  dmp.diff_cleanupSemantic(diff);
}
var patch_list = dmp.patch_make(data1, data2, diff);
var patch_text = dmp.patch_toText(patch_list);

var ms_end = (new Date).getTime();
fs.writeFile(path.resolve(__dirname, '../dist/business.patch'),patch_text,function(err){
    if(err){
        console.log(err);
    }else{
        var time = (ms_end - ms_start) / 1000 + 's';
        console.log("生成patch包成功\n")
        console.log("耗时:"+ time);
    }
})