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
function ShowSearchResults()
{
    var $search_div = $('[id="search-results"]');
    $search_div.show();
    var $search_div = $('[id="instructions"]');
    $search_div.hide();
    var $group_div = $('[id="group-results"]');
    $group_div.hide();
    
}

function ShowGroupResults()
{
    var $search_div = $('[id="search-results"]');
    $search_div.hide();
    var $search_div = $('[id="instructions"]');
    $search_div.hide();
    var $group_div = $('[id="group-results"]');
    $group_div.show();

}

function ShowHelp()
{
    var $search_div = $('[id="search-results"]');
    $search_div.hide();
    var $search_div = $('[id="instructions"]');
    $search_div.show();
    var $group_div = $('[id="group-results"]');
    $group_div.hide();

}
function ShowDominicans()
{
    var win = window.open("http://www.op.org", '_blank');
    win.focus();
}

function Search()
{
    var $domain_summary_div = $('[name="domain_summary_pages"]');
    var $cloned_summary=$domain_summary_div.clone();
    var $specific_div = $('[id="specific_action_variables"]');
    $specific_div = $specific_div.empty();
    $specific_div.html($cloned_summary);
    $("#search_notice").empty();
    $("#search_notice").text("Please wait ...");
    $("#search_notice").show();
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

function CrawlerPageRange(page_id)
{
    crawler_page_id_obj = $('[id="crawler_page_id"]');
    crawler_page_id_obj.attr("value", page_id);
    crawler_page_action_obj = $('[id="crawler_page_action"]');
    crawler_page_action_obj.attr("value", "page-range");
    expand_contract_radio_obj = $('[name="expand_contract_radio"]');
    expand_contract_radio_obj.attr("value", true);
    expand_contract_form_obj = $('[id="expand_contract_form"]');
    expand_contract_form_obj.submit();
}


function expandCrawlerPage( page_id) {

    //ul_ref_obj_str = 'ul-crawler-page-' + page_id;
    //ul_ref_obj = $('[name="ul-crawler-page-'+ page_id+'"]');

    
    //ul_ref_obj.show();

  //  contract_ref_obj = $('[name="contract-button-'+ page_id+'"]');
   // contract_ref_obj.show();
   // expand_ref_obj = $('[name="expand-button-'+ page_id+'"]');
  //  expand_ref_obj.hide();
    crawler_page_id_obj = $('[id="crawler_page_id"]');
    crawler_page_id_obj.attr("value", page_id);
    crawler_page_action_obj = $('[id="crawler_page_action"]');
    crawler_page_action_obj.attr("value", "expand-contract");
    expand_contract_radio_obj = $('[name="expand_contract_radio"]');
    expand_contract_radio_obj.attr("value", true);
    expand_contract_form_obj = $('[id="expand_contract_form"]');
    expand_contract_form_obj.submit();
}

function contractCrawlerPage( page_id) {
  //  ul_ref_obj_str = 'ul-crawler-page-' + page_id;
  //  ul_ref_obj = $('[name="ul-crawler-page-'+ page_id+'"]');


 //   ul_ref_obj.hide();

//    contract_ref_obj = $('[name="contract-button-'+ page_id+'"]');
 //   contract_ref_obj.hide();
 //   expand_ref_obj = $('[name="expand-button-'+ page_id+'"]');
//    expand_ref_obj.show();
    crawler_page_id_obj = $('[id="crawler_page_id"]');
    crawler_page_id_obj.attr("value", page_id);
    crawler_page_action_obj = $('[id="crawler_page_action"]');
    crawler_page_action_obj.attr("value", "expand-contract");
    expand_contract_radio_obj = $('[name="expand_contract_radio"]');
    expand_contract_radio_obj.attr("value", false);
    expand_contract_form_obj = $('[id="expand_contract_form"]');
    expand_contract_form_obj.submit();
}
function ProcessMore()
{
    form_obj = $('[id="process_more_results_form"]');
    form_obj.submit();    
}
function MoreResults(more_results_current_index, more_results_range)
{
    $("#results_current_index").attr("value", more_results_current_index);
    $("#results_range").attr("value", more_results_range);
    form_obj = $('[id="more_results_form"]');
    form_obj.submit();


}
function TidyUp()
{
    form_obj = $('[id="tidy_up_form"]');
    form_obj.submit();    
}

function SelectPreviousSearch(argss)
{
    val =  $("#select-previous-search option:selected").val();
    
    index =  $("#select-previous-search").prop('selectedIndex');
    args = argss[index];

    $("#word1").attr("value", args[0]);
    $("#word2").attr("value", args[1]);
    $("#word3").attr("value", args[2]);
    $("#word4").attr("value", args[3]);
    $("#word_separation").val(args[4]).change();
    $("#prev_query_id").attr("value", val);


}


function SelectDomainAction()
{

    $("#group_notice").empty();
    obj = $("#select-domain-action option:selected");
    value = obj.val();
    switch(value) {
        case "select_action":
            $( ".domain-field" ).hide();
            break;
        case "new_domain":
            $( ".domain-field" ).hide();
            $( ".domain-new" ).show();
            $("#new_domain_action").prop('value', 'new_domain');
            break;
        case "grab_domain":
            $( ".domain-field" ).hide();
            $( ".domain-new" ).show();
            $("#new_domain_action").prop('value', 'grab_domain');
            break;
        
        case "analyse_domain":
            $( ".domain-field" ).hide();
            $( ".domain-new" ).show();
            $(".bad_page").hide();
            $(".domain-checkbox").show();
            $( ".domain-action-button" ).show();
            $("#domain_flow").show();
            $("#domain-action-button").prop('value', 'Analyse Domain');
            break;           
        
        
        case "fix_domain":
            $( ".domain-field" ).hide();
            $( ".domain-new" ).show();
            $(".bad_page").show();
            $(".domain-name-radio").show();
            $( ".domain-action-button" ).show();
            $("#domain-action-button").prop('value', 'Fix Domain');
            break;
        case "reorder_pages":
            $( ".domain-field" ).hide();
            $( ".domain-new" ).show();
            $(".bad_page").show();
            $(".domain-name-radio").show();
            $( ".domain-action-button" ).show();
            $("#domain-action-button").prop('value', 'Reorder Pages');
            break;
        case "deaccent_domain":
            $( ".domain-field" ).hide();
            $( ".domain-new" ).show();
            $(".bad_page").show();
            $(".domain-name-radio").show();
            $( ".domain-action-button" ).show();
            $("#domain-action-button").prop('value', 'Deaccent Domain');
            break;
            
        case "set_paragraphs":
            $( ".domain-field" ).hide();
            $( ".domain-new" ).show();
            $(".bad_page").show();
            $(".domain-name-radio").show();
            $( ".domain-action-button" ).show();
            $("#domain-action-button").prop('value', 'Set Paragraphs');

            break;
        case "search_domain":
            $( ".domain-field" ).hide();
            $(".domain-checkbox").show();
            $(".bad_page").hide();
            $( ".search-new" ).show();
            $(".search-old").show();
            $('[id="search_type"]').prop('value', "search_domains");
            break;
        
        case "search_groups":
            $( ".domain-field" ).hide();
            $(".domain-checkbox").show();
            $(".bad_page").hide();
            $( ".search-new" ).show();
            $(".search-old").show();
            $('[id="search_type"]').prop('value', "search_groups");
            break;
        
        case "move_domain":
            $(".domain-field").hide();
            //$(".domain-name-radio").show();
            $(".domain-checkbox").show();
            $(".move-location-domain-name-radio").show();
            $( ".domain-action-button" ).show();
            $("#domain-action-button").prop('value', 'Move Selected');


            break;
        case "rename":
            $( ".domain-field" ).hide();
            $( ".domain-action-button" ).show();
            $(".domain_action_name").show();
            $(".domain-name-radio").show();
            $("#domain-action-button").prop('value', 'Rename Page');
            
            break;
        case "remove_domain":
            $( ".domain-field" ).hide();
            $( ".remove-domain" ).show();
            $("#domain-action-button").prop('value', 'Remove Page');
            break;


        default:
            alert("something has gone wrong");
    }



}

function SelectGroupAction()
{
    $("#search_notice").empty();
    $("#group_notice").empty();
    obj = $("#select-group-action option:selected");
    value = obj.val();
//alert("value = " + obj.val());
    switch(value) {
        case "select_action":
            $( ".group-field" ).hide();
            break;
        case "new_group":
            $( ".group-field" ).hide();
            $( ".group-action-button" ).show();
            $(".group_action_name").show();
            $(".group-name-radio").show();
            $("#group-action-button").prop('value', 'Create Group');
            $("#group_action_name").text("New Group Name");
            break;

        case "move_group":
            $(".group-field").hide();
            $(".group-name-radio").show();
            $(".move-location-group-name-radio").show();
            $( ".group-action-button" ).show();
            $("#group-action-button").prop('value', 'Move Selected');

           
            break;
        case "add_element":
            $( ".group-field" ).hide();
            $(".search-check-box").show();
            $( ".add-result" ).show();
            ShowSearchResults();
            break;
        case "remove_element":
            $( ".group-field" ).hide();
            $("[name='remove_elements_button']").show();
            
            ShowGroupResults();
            break;

        case "rename":
            $( ".group-field" ).hide();
            $( ".group-action-button" ).show();
            $(".group_action_name").show();
            $(".group-name-radio").show();
            $("#group-action-button").prop('value', 'Rename Group');
            $("#group_action_name").text("New Group Name");
            break;
        case "remove_group":
            $( ".group-field" ).hide();
            $( ".remove-group" ).show();
            $("#group-action-button").prop('value', 'Remove Group');
            break;


        default:
        alert("something has gone wrong");
    }
}
function RemoveFromGroup()
{
    form_obj = $('[id="remove_group_result_form"]');
    form_obj.submit();   
}

function AddToGroup(group_id)
{
    $("#add_elements_group_id").val(group_id);
    form_obj = $('[id="add_result_form"]');
    form_obj.submit();
    
}

function RemoveGroup(group_id)
{
    form_obj = $('[id="group_action_form"]');

    $('[name="remove_group"]').prop('value', group_id);
    form_obj.submit();


}

function RemoveDomain(crawler_page_id)
{
    form_obj = $('[id="domain_action_form"]');

    $('[name="remove_domain"]').prop('value', crawler_page_id);
    form_obj.submit();


}


function expandGroupName( group_name_id) {

    ul_ref_obj_str = 'ul-group-name-' + group_name_id;
    ul_ref_obj = $('[name="ul-group-name-'+ group_name_id+'"]');


    ul_ref_obj.show();

    contract_ref_obj = $('[name="group-contract-button-'+ group_name_id+'"]');
    contract_ref_obj.show();
    expand_ref_obj = $('[name="group-expand-button-'+ group_name_id+'"]');
    expand_ref_obj.hide();
}

function contractGroupName( group_name_id) {
    ul_ref_obj_str = 'ul-group-name-' + group_name_id;
    ul_ref_obj = $('[name="ul-group-name-'+ group_name_id+'"]');


    ul_ref_obj.hide();

    contract_ref_obj = $('[name="group-contract-button-'+ group_name_id+'"]');
    contract_ref_obj.hide();
    expand_ref_obj = $('[name="group-expand-button-'+ group_name_id+'"]');
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