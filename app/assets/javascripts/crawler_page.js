/**
 * Created by robert on 07/07/16.
 */
var old_crawler_page_id = 1;
function SelectDomain(new_crawler_page_id 
){

    selector_obj =$('[name="domain-selector-'+ new_crawler_page_id+'"]');
 //   selector_obj.show();
    if(new_crawler_page_id != old_crawler_page_id){
        selector_obj =$('[name="domain-selector-'+ old_crawler_page_id+'"]');
 //       selector_obj.hide();
        old_crawler_page_id = new_crawler_page_id;
    }
}


function Search()
{
    var $domain_summary_div = $('[name="domain_summary"]');
    var $cloned_summary=$domain_summary_div.children().first().clone();
    var $specific_div = $('[id="specific_action_variables"]');
    $specific_div = $specific_div.empty();
    $specific_div.html($cloned_summary);
    form_obj = $('[id="search_form"]');
    form_obj.submit();
}

function SelectCrawlerPage( page_id) {

    ul_ref_obj_str = 'ul-crawler-page-' + page_id;
    ul_ref_obj = $('[name="ul-crawler-page-'+ page_id+'"]');

    check_ref_obj = $('[id="checkbox-domain-selector-'+ page_id+'"]');
    if(check_ref_obj.is(':checked'))
    {
        $('[name="ul-crawler-page-'+ page_id+'"]').find(':checkbox').each(function(){ this.checked = true; });
    }
    else
    {
        $('[name="ul-crawler-page-'+ page_id+'"]').find(':checkbox').each(function(){ this.checked = false; });
    }

    //ul_ref_obj.show();

  //  contract_ref_obj = $('[name="contract-button-'+ page_id+'"]');
  //  contract_ref_obj.show();
   // expand_ref_obj = $('[name="expand-button-'+ page_id+'"]');
   // expand_ref_obj.hide();
}

function expandCrawlerPage( page_id) {

    ul_ref_obj_str = 'ul-crawler-page-' + page_id;
    ul_ref_obj = $('[name="ul-crawler-page-'+ page_id+'"]');

    
    ul_ref_obj.show();

    contract_ref_obj = $('[name="contract-button-'+ page_id+'"]');
    contract_ref_obj.show();
    expand_ref_obj = $('[name="expand-button-'+ page_id+'"]');
    expand_ref_obj.hide();
}

function contractCrawlerPage( page_id) {
    ul_ref_obj_str = 'ul-crawler-page-' + page_id;
    ul_ref_obj = $('[name="ul-crawler-page-'+ page_id+'"]');


    ul_ref_obj.hide();

    contract_ref_obj = $('[name="contract-button-'+ page_id+'"]');
    contract_ref_obj.hide();
    expand_ref_obj = $('[name="expand-button-'+ page_id+'"]');
    expand_ref_obj.show();
}


function ShowItem(item_name){

    
    ref_obj = $('[name="'+ item_name+'"]');
    ref_obj.show();
    show_link_ref_obj_str = "show_link_"+item_name;
    show_link_ref_obj = $('[name="'+show_link_ref_obj_str+'"]');
    show_link_ref_obj.hide();
    hide_link_ref_obj_str = "hide_link_"+item_name;
    hide_link_ref_obj = $('[name="'+hide_link_ref_obj_str+'"]');
    hide_link_ref_obj.show();
}

function HideItem(item_name){

    ref_obj = $('[name="'+ item_name+'"]');
    ref_obj.hide();
    show_link_ref_obj_str = "show_link_"+item_name;
    show_link_ref_obj = $('[name="'+show_link_ref_obj_str+'"]');
    show_link_ref_obj.show();
    hide_link_ref_obj_str = "hide_link_"+item_name;
    hide_link_ref_obj = $('[name="'+hide_link_ref_obj_str+'"]');
    hide_link_ref_obj.hide();
}
function selectionNewDomain( page_id) {


}